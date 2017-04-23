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

def get_disks():
    disks = []
    for name in os.listdir(PATH):
        udev_device, sysname, bus, path = name.split("-", 3)
        path = path.split('-')
        if path[-1].startswith('part'):
            part = path.pop(-1)
        else:
            part = None
        path = '-'.join(path)
        
        dev_name = os.readlink(os.path.join(PATH, name)).split('/')[-1]
        
        disk = Disk(udev_device=udev_device,
            sysname=sysname, bus=bus, path=path, part=part,
            dev_name=dev_name)
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


