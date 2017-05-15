# Building a Fedorator

The Fedorator was designed as open hardware made from readily available
components.  This means anybody from all around the world can build one,
should they wish!

Fair warning: the Fedorator is still a prototype and there are several
known improvements planned.  It may be a good idea to hold off on trying to
build one until the next revision.

## Components

The Fedorator makes use of the following components.

 * Raspberry Pi 3 Model B
 * MicroSD card (at least 16 GB recommended)
 * 3.5 inch Raspberry Pi model B compatible touchscreen (at least 480*320)
 * Two short USB extender cables (male to female)
 * Micro-USB powering cable

You will need to get ahold of these components yourself.  As a tip, there
are many resellers of the Raspberry Pi around the world listed
[here](http://farnell.com/raspberrypi-consumer/approved-retailers.php), or
you can simply make an Internet search in your local area.

In order to make the case, a 3D printer is required.

## Software

The Fedorator software can run on both the officially sanctioned [Raspbian](https://www.raspberrypi.org/downloads/raspbian/)
distribution, as well as [Fedora](https://getfedora.org/), which supports
Raspberry Pi natively since version 25.

Sadly, you may find yourself requiring the Raspbian distribution, because
many of the cheaper displays require proprietary binary drivers only compiled
for the Raspbian kernel.

Install and boot into your operating system.

Log in and follow these instructions to set up the Fedorator software.

    $  # First, install requirements
    $  # On Fedora
    $ sudo dnf install git python3-virtualenv redhat-rpm-config mesa-libGL-devel
    
    $  # On Raspbian
    $ sudo apt-get install git python3-virtualenv cython3 libsdl1.2-dev
    $  # if testing with a DE
    $ sudo apt-get build-dep python3-pygame
     
    $  # Clone this repository into the home directory
    $ git clone https://github.com/Sanqui/fedorator
    $ cd fedorator/src
     
    $  # Set up the virtualenv
    $ python3 -m virtualenv --python=python3 env
    $ source env/bin/activate
    $ pip install cython
    $ pip install -r requirements.txt
     
    $ # if testing with a DE
    $ pip install pygame

To run the software now, simply do

    $ python3 main.py
    
If an Xorg session is present, the software is better tested with `./test.sh`,
which sets the window resolution to 320*480.

If the software is working, we can download some image files, or .isos, which
will then be made available for writing to USB flash drives.

`releases.py` is a simple script to download the most common Fedora images.
By default, it attempts to download 10 images.  You may set the number of
desired images by passing it as the argument.  Keep in mind that each image
is about 1.5 GiB large.  

    $ python3 releases.py

The Fedorator software needs to run as root and should start on system boot
and run indefinedly.  On Raspian, this can be accomplished by adding the
following to `/etc/rc.local`:
    
    cd /home/pi/fedorator/src
    source env/bin/activate
    python3 main.py &

## Hardware-specific setup

The Fedorator is designed to have the screen positioned vertically.  Displays will
require some sort of manual configuration in order to rotate.  For example, on
Raspbian, a common way to rotate the display is by appending `display_rotate=1` to
`/boot/config.txt`.

In case the touch screen coordinates are inverted, this can be patched in kivy by
editing the config in `~/.kivy/config.ini`.

## Assembly

The Fedorator requires some manual assembly.

The case for the Fedorator is split into two components, which may be defined as inner and outer, or bottom and top.  These two components are printed separately, but lock together when the device is constructed.

The **inner part** consists of the floor, a pair of supports designated for USB connectors, and a holder for the Raspberry Pi and display pair.

The **outer part** is majorly the shell and cap.  There are four holes in the shell, one for the display, two for the USB ports, and one in the back for the power cable.

Both parts are designed in such a way that they fit snugly together.  The top part can be carefully put over the bottom part and holds well unless taken by force.

The current version, in a misguided attempt at making assembly simple, does
not contain any screws or fastening bolts to hold the components in place.
Instead, if the sealing isn't tight enough, components may be fixed by other
means, such as tightening strap.

### Printing the case

The case can be found in `case/case.scad`.  It may be edited and exported
with OpenSCAD.  As a parametric object, it's possible to adjust the values to
your liking, however keep in mind that there must be space reserved for
cable connectors.

The case is best printed from the PLA material, but ABS should work also
if PLA is not available.  A dark blue filament color is preferred as that is
the color of the Fedora brand.

You should use the settings recommended for your printer.  Adding supports is
recommended if you are not confident in your printer's ability to make
bridges.

### Inserting the components

Seat the Raspberry Pi and display into the inner component.  Connect the two
extender cables and place them onto the supports at the bottom of the device.
Use a cable tie to hold the USB connectors in place.  Connect the Micro-USB
cable for power to the Raspberry Pi.

If everything is in order, carefully push the top part of the case into the
bottom one.  Small adjustments may be necessary to the components if they are
off after connecting the case.


