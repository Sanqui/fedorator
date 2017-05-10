import os
import sys

from sendfile import sendfile

from tqdm import tqdm

BUFFSIZE = (1024 ** 2) * 2 # 2MB

def write(filepath, target):
    filesize = os.path.getsize(filepath)
    fin = open(filepath, 'rb')
    
    fout = open(target, 'wb')
    
    offset = 0
    while True:
        copied = sendfile(fout.fileno(), fin.fileno(), offset, BUFFSIZE)
        if not copied: break
        pbar.update(copied)
        offset += copied
        
        yield copied


if __name__ == "__main__":
    filepath = sys.argv[1]
    target = sys.argv[2]
    filesize = os.path.getsize(filepath)
    
    
    with tqdm(total=filesize, unit='B', unit_scale=True) as pbar:
        for copied in write(filepath, target):
            pbar.update(copied)
    
    
