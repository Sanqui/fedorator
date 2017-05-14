import os
import sys
import logging

from sendfile import sendfile
from tqdm import tqdm

import usbdisks

BUFFSIZE = (1024 ** 2) * 2 # 2MB

def filesize(filepath):
    return os.path.getsize(filepath)

def write(filepath, target):
    """
        Copy a large file while reporting progress.
        
        This function uses sendfile() to achieve fast copying of data.
    """
    logging.log(logging.INFO, "Writing {} to {}.".format(filepath, target))
    device = False
    if target.startswith("/dev"):
        device = True
    
    if device:
        logging.log(logging.INFO, "Target is a device, will attempt to unmount.")
        for disk in usbdisks.get_disks():
            if disk.fs_path.startswith(target):
                logging.log(logging.INFO, "Unmounting {}.".format(disk.fs_path))
                os.system("umount "+disk.fs_path)
    
    filesize = os.path.getsize(filepath)
    fin = open(filepath, 'rb')
    
    fout = open(target, 'wb')
    
    offset = 0
    while True:
        copied = sendfile(fout.fileno(), fin.fileno(), offset, BUFFSIZE)
        if not copied: break
        offset += copied
        
        yield copied
    
    if device:
        os.system('udisksctl power-off -b '+target)

if __name__ == "__main__":
    filepath = sys.argv[1]
    target = sys.argv[2]
    filesize = filesize(filepath)
    
    
    with tqdm(total=filesize, unit='B', unit_scale=True) as pbar:
        for copied in write(filepath, target):
            pbar.update(copied)
    
    
