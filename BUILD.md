# Building a Fedorator

The Fedorator was designed as open hardware made from readily available
components.  This means anybody from all around the world can build one,
should they wish!

Fair warning: the Fedorator is still a prototype and there are several
known improvements planned.

## Components

The Fedorator makes use of the following components.

 * Raspberry Pi 3 Model B
 * MicroSD card (at least 16 GB recommended)
 * 3.5 inch Raspberry Pi model B compatible touchscreen (at least 480*320)
 * Two USB extender cables (male to female)

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

(TODO: autorun)

## Hardware-specific setup

The Fedorator is designed to have the screen positioned vertically.  Displays will
require some sort of manual configuration in order to rotate.  For example, on
Raspbian, a common way to rotate the display is by appending `display_rotate=1` to
`/boot/config.txt`.

In case the touch screen coordinates are inverted, this can be patched in kivy by
editing the config in `~/.kivy/config.ini`.  (TODO: which lines)

## Assembly

The assembly isn't particularly involved.

(TODO: write about assembly)
