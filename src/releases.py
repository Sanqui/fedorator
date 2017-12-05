from pprint import pprint
import json
import os
from os import listdir
import os.path as path
from sys import argv, stderr
from shutil import disk_usage

from tqdm import tqdm
import requests

# VERSION = 26
RELEASES_URL = "https://getfedora.org/releases.json"

ARCH_PRIORITY = ["x86_64", "i386"]
SUBVARIANT_PRIORITY = ["workstation", "server", "kde", "xfce", "lxde", "cinnamon", "mate_compiz", "python_classroom"]
BLACKLIST = "netinst ostree".split()

DEFAULT_ARCH = ARCH_PRIORITY[0]
MINIMUM_FREE_SPACE = 64*1024*1024 # keep 64MiB

DOWNLOAD_DIRECTORY = "iso"
BUFFSIZE = (1024 ** 2) * 4 # 4MB

TOUCH_ONLY = False

total_space, used_space, free_space = disk_usage(DOWNLOAD_DIRECTORY)
#releases_json = requests.get("https://getfedora.org/releases.json").json()

releases = json.load(open("data/metadata.json", encoding="utf-8"))

if __name__ == '__main__':
    try:
        images_new = requests.get(RELEASES_URL).json()
        images = images_new
        json.dump(images, open("data/releases.json", "w"))
    except requests.exceptions.ConnectionError:
        print("Cannot reach {}".format(RELEASES_URL))

images = json.load(open("data/releases.json"))
    
VERSION = max([i['version'] for i in images])

for image in images:
    image['size'] = int(image['size'])
    image['filename'] = image['link'].split('/')[-1]
    image['netinst'] = 'netinst' in image['filename'].split('-')

for release in releases:
    release['images'] = []
    for image in images:
        if image['subvariant'].lower() == release['subvariant'].lower():
            release['images'].append(image)
    release['images'].sort(key=lambda image: ARCH_PRIORITY.index(image['arch']) if image['arch'] in ARCH_PRIORITY else 9)

downloaded_images = listdir(DOWNLOAD_DIRECTORY)
downloaded_images.remove("README")


images_by_priority = []

for subvariant in SUBVARIANT_PRIORITY:
    for arch in ARCH_PRIORITY:
        for image in images:
            if image['subvariant'].lower() == subvariant \
              and image['arch'] == arch \
              and image['version'] == str(VERSION) \
              and not any(b in image['filename'].split("-") for b in BLACKLIST) \
              and image['filename'].endswith('.iso'):
                images_by_priority.append(image)

for image in images:
    if not image in images_by_priority \
      and image['version'] == str(VERSION) \
      and image['filename'].endswith('.iso'):
        images_by_priority.append(image)

outdated_images = set(downloaded_images) - set(i['filename'] for i in images_by_priority)
outdated_images_size = sum(path.getsize(DOWNLOAD_DIRECTORY+"/"+f) for f in outdated_images)
kept_images = set(downloaded_images) - set(outdated_images)

iso_free_space = free_space + outdated_images_size - MINIMUM_FREE_SPACE

images_to_download = []
for image in images_by_priority:
    if image['filename'] not in downloaded_images:
      if iso_free_space - image['size'] > 0:
          iso_free_space -= image['size']
          images_to_download.append(image)
      else:
          break

def get_image_path(release, version, arch):
    version = str(version)
    image = None
    for i in release['images']:
        if i['arch'] == arch and i['version'] == version \
          and 'netinst' not in i['link']:
            image = i
    if not image:
        return None
    
    filename = image['link'].split('/')[-1]
    filepath = os.path.join("iso", filename)
    if not os.path.isfile(filepath):
        return None
    
    return filepath

def have_any_image(release, version):
    for arch in ARCH_PRIORITY:
        if get_image_path(release, version, arch):
            return True
    return False

def download(url):
    """ Download a file while reporting progress. """
    filename = url.split('/')[-1]
    filepath = path.join(DOWNLOAD_DIRECTORY, filename)
    if TOUCH_ONLY:
        open(filepath, "w")
        return
    try:
        f = open(filepath, "wb")
        
        r = requests.get(url, stream=True)
        
        filesize = int(r.headers['Content-length'])
        
        
        with tqdm(total=filesize/BUFFSIZE*4, unit='MiB') as pbar:
            for chunk in r.iter_content(chunk_size=BUFFSIZE):
                if chunk:
                    f.write(chunk)
                    pbar.update(4)
    except:
        os.remove(filepath)
        raise

if __name__ == '__main__':
    print("Latest Fedora version is {}.".format(VERSION))
    print("There is {:.02} GiB of free space.".format(free_space/(1024**3)))
    print("{} images already downloaded, {} of which are outdated".format(len(downloaded_images), len(outdated_images)))
    if kept_images:
        print("The following images are to be kept.")
        for outdated_image in kept_images:
            print(" * {}".format(outdated_image))
    if outdated_images:
        print("The following outdated images are to be deleted.")
        for outdated_image in outdated_images:
            print(" * {}".format(outdated_image))
        print("This will free up {:.02} GiB of space.".format(outdated_images_size/(1024**3)))
    if images_to_download:
        print("The following {} images are to be downloaded.".format(len(images_to_download)))
        for image_to_download in images_to_download:
            print(" * {}".format(image_to_download['filename']))
        print("There will be {:.02} GiB's worth of free space.".format(iso_free_space/(1024**3)))
        #delete = 
    else:
        print("There are no images to download (probably due to lack of space).")
    if outdated_images or images_to_download:
        proceed = input("Is this OK?  [Y/N] ").lower() == "y"
        if proceed:
            if outdated_images:
                for outdated_image in outdated_images:
                    os.remove(DOWNLOAD_DIRECTORY+'/'+outdated_image)
                print("The {} outdated images were deleted.".format(len(outdated_images)))
            if images_to_download:
                print("Will download {} images".format(len(images_to_download)))
                
                for i, image in enumerate(images_to_download):
                    tqdm.write("[{}/{}] Downloading {}...".format(i, len(images_to_download), image['link']))
                    download(image['link'])
