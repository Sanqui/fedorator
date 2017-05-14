from pprint import pprint
import json
import os
from os import listdir
import os.path as path
from sys import argv

from tqdm import tqdm
import requests

VERSION = 25
ARCH_PRIORITY = ["x86_64", "i386"]
SUBVARIANT_PRIORITY = ["workstation", "server", "kde", "xfce", "lxde"]

MAX_IMAGES = int(argv[1]) if len(argv) >= 2 else 10

DEFAULT_ARCH = ARCH_PRIORITY[0]
DEFAULT_VERSION = VERSION

DOWNLOAD_DIRECTORY = "iso"
BUFFSIZE = (1024 ** 2) * 4 # 4MB

def download(url):
    """ Download a file while reporting progress. """
    filename = url.split('/')[-1]
    filepath = path.join(DOWNLOAD_DIRECTORY, filename)
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

images = json.load(open("data/releases.json"))
releases = json.load(open("data/metadata.json"))

for release in releases:
    release['images'] = []
    for image in images:
        if image['subvariant'].lower() == release['subvariant'].lower():
            release['images'].append(image)
    release['images'].sort(key=lambda image: ARCH_PRIORITY.index(image['arch']) if image['arch'] in ARCH_PRIORITY else 9)

downloaded_images = listdir("iso/")
downloaded_images.remove("README")

images_by_priority = []

for subvariant in SUBVARIANT_PRIORITY:
    for arch in ARCH_PRIORITY:
        for image in images:
            if image['subvariant'].lower() == subvariant \
              and image['arch'] == arch \
              and image['version'] == str(VERSION) \
              and 'netinst' not in image['link'] \
              and image['link'].split('/')[-1] not in downloaded_images:
                images_by_priority.append(image)

for image in images:
    if not image in images_by_priority:
        images_by_priority.append(image)

if __name__ == '__main__':
    num = min(MAX_IMAGES - len(downloaded_images), len(images_by_priority))
    if num > 0:
        print("Will download {} images".format(num))
        
        for image in tqdm(images_by_priority[:10]):
            tqdm.write("Downloading {}...".format(image['link']))
            download(image['link'])
    else:
        print("{} images present, nothing to do.".format(len(downloaded_images)))
        
        print(num)
