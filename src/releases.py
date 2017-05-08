import json
from os import listdir

ARCH_PRIORITY = ["x86_64", "i386"]
SUBVARIANT_PRIORITY = ["workstation", "server", "kde", "xfce", "lxde"]

images = json.load(open("data/releases.json"))
releases = json.load(open("data/metadata.json"))

MAX_IMAGES = 10

for release in releases:
    release['images'] = []
    for image in images:
        if image['subvariant'].lower() == release['subvariant'].lower():
            release['images'].append(image)

downloaded_images = listdir("iso/")
downloaded_images.remove("README")

if __name__ == '__main__':
    if len(downloaded_images) < MAX_IMAGES:
        num = MAX_IMAGES - downloaded_images
        print("Will download {} images".format(num))
        
        
