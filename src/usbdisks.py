import os, os.path
from attr import attrs, attrib

PATH = "/dev/disk/by-path"

@attrs
class Disk():
    udev_device = attrib()
    sysname = attrib()
    bus = attrib()
    path = attrib()
    part = attrib()
    
    dev_name = attrib()
    
    size = attrib()

@attrs
class DiskSize():
    major = attrib()
    minor = attrib()
    blocks = attrib()
    bytes = attrib()

def get_disk_sizes():
    disk_sizes = {}
    f = open('/proc/partitions')
    f.readline()
    f.readline()
    for line in f.readlines():
        major, minor, blocks, name = line.strip().split()
        disk_sizes[name] = DiskSize(
            major=int(major), minor=int(minor), blocks=int(blocks),
            bytes=int(blocks)*1024) # XXX
    
    return disk_sizes

def get_disks():
    disk_sizes = get_disk_sizes()
    disks = []
    for name in os.listdir(PATH):
        parts = name.split("-", 3)
        if len(parts) == 4:
            udev_device, sysname, bus, path = parts
        elif len(parts) == 3:
            udev_device, sysname, path = parts
            bus = None
        elif len(parts) == 2:
            udev_device, sysname = parts
            path = None
        if path:
            path = path.split('-')
            if path[-1].startswith('part'):
                part = path.pop(-1)
            else:
                part = None
            path = '-'.join(path)
        
        dev_name = os.readlink(os.path.join(PATH, name)).split('/')[-1]
        
        disk = Disk(udev_device=udev_device,
            sysname=sysname, bus=bus, path=path, part=part,
            dev_name=dev_name,
            size=disk_sizes.get(dev_name))
        disks.append(disk)
    
    return disks

def get_usb_disks():
    disks = []
    for disk in get_disks():
        if disk.bus == 'usb' and not disk.part:
            disks.append(disk)
    
    return disks

if __name__=="__main__":
    from pprint import pprint
    pprint(get_usb_disks())


