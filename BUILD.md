# Building a Fedorator

The Fedorator was designed as open hardware made from readily available
components.  This means anybody from all around the world can build one,
should they wish.

## Components

The Fedorator makes use of the following components.

 * Raspberry Pi 3 Model B
 * MicroSD card (at least 16 GB recommended)
 * [Raspberry Pi touch display](https://www.raspberrypi.org/products/raspberry-pi-touch-display/)
 * 2x [USB panel mount](https://www.amazon.com/StarTech-com-Panel-Mount-USB-Cable/dp/B002M8RVKA)
 * Micro-USB powering cable (at least 2A, e.g. [from CanaKit](https://www.canakit.com/raspberry-pi-adapter-power-supply-2-5a.html))
 * 8x M3 screw
 * 4x GF2 rubber foot

You will need to get ahold of these components yourself.  As a tip, there
are many resellers of the Raspberry Pi around the world listed
[here](http://farnell.com/raspberrypi-consumer/approved-retailers.php), or
you can simply make an Internet search in your local area.

In order to make the case, a 3D printer is required.

## Software

The Fedorator software runs on both the [Raspbian](https://www.raspberrypi.org/downloads/raspbian/)
distribution, as well as [Fedora](https://arm.fedoraproject.org/).  Sadly, the official Raspberry Pi screen is not
yet supported Fedora; this situation should change soon, though, however.

In order to set up a Fedorator environment, follow the following instruction.

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
which sets the correct screen resolution.

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
editing the config in `~/.kivy/config.ini` (as well as `/root/.kivy.config.ini`).

TODO: Provide the exact instructions for this.

## Assembly

The Fedorator requires manual assembly.

### Printing the case

The case can be found in `case/case.scad`.  It may be edited and exported
with OpenSCAD.  As a parametric object, it's possible to adjust the values to
your liking, however keep in mind that a lot of parts are meticulously aligned.

The case is best printed from the PLA material.  A dark blue filament color,
e.g. [True Blue](https://www.lulzbot.com/store/filament/polylite-pla?product_filament_colors=192), is recommended.

Make sure supports are in use for the two arms suppporting the display.

## Setup

Photographic instructions are coming soon.

 1. Remove all supports from the 3D printed case.
 2. Insert the rubber legs and screw them in using 3M screws.
 3. Insert the USB panels and fasten the screws.
 4. Take the Raspberry Pi and connect it to the display, by first tightening the screws, then connecting the display using the flex cable.  Use the jumper cables to connect the first and third Raspberry Pi pin to the first and fifth display pin.
 5. Pass the MicroUSB cable through the round hole at the back side of the case.
 6. Connect the MicroUSB cable to the Raspberry Pi.
 7. Connect the USB panel mounts to the Rasberry Pi.
 8. Lay down the Raspberry Pi and display on top of the case.
 9. Fasten all four screws connecting the screen.
 10. Insert the MicroSD card containing the system in the Raspberry Pi

Now the Fedorator should be ready to plug in and function.

