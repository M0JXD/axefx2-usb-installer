#!/bin/sh

# WIP installer

# Note - while I can get FreeBSD to get the firmware uploaded with fxload,
# the soundcard is not detected unless the USB is replugged after.
echo -e "Stupid simple/dangerous AXE-FX II installer for FreeBSD.\nYou will need to be root and should have already installed fxload."
cp -vf axefx2load.hex /usr/local/share/fxload/
cp -vf fractal.conf /usr/local/etc/devd/
