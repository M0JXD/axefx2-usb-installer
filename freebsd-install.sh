#!/bin/sh

# WIP installer

# Note - while I can get FreeBSD to get the firmware uploaded with fxload,
# the soundcard is not detected unless the USB is replugged after.
echo -e "Stupid simple/dangerous installer for FreeBSD. You will need to be root"
cp -f axefx2load.hex /usr/local/share/fxload/
cp -f fractal.conf /usr/local/etc/devd/
