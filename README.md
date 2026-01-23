# Axe-FX II USB Firmware Installation Script for Linux.

A recent update to libusb's version of fxload broke the -D option.
Most distro's are using Hotplug project's version which has been unchanged since 2008, but for Arch it's the "libusb" project. Due to the only versioning being the C DATE macro (that changes with every rebuild) it's hard to tell which you have.
This is a modified installation script for the Axe-FX II USB Firmware that detects the installed version of fxload via it's error message and sets the appropriate udev rule.

Joachim Gahl (the original script writer) has kindly permitted me to modify the script, although if you wish to make changes you will require his permission. (My permission may be taken as a given.)
As per the previous versions, these changes do not provide/imply any warranties/guarantees/liabilities.

This script was modified on Ubuntu Cinnamon 24.04.

## Original Readme

This installer will install the Axe-FX II USB Audio Class 2.0 firmware and firmware daemon.

System Requirements:
LINUX kernel 2.6.35+, bash, udev, fxload

Notes:
The Axe-FX II relies on the host computer to upload the USB firmware when connecting to the host after a reboot. The USB firmware daemon resides on the host computer and is responsible for uploading the USB firmware silently as needed. This is achieved by a udev rule executing a program named "fxload" (http://sourceforge.net/projects/linux-hotplug/files/fxload/). If fxload is not already present on your system you will have to install it prior to running the script named "axefx2setup.sh". Otherwise the script will abort.

Run the script with root privileges using the bash. It will create a udev rules file for the Axe-FX II and copy the bootloader firmware file into "/usr/share/usb/FractalAudio/axefx2/". Non existent folders will be created automatically.

The Axe-FX II is a UAC2 compliant device. Kernel versions since 2.6.35 are considered to be UAC2 ready, but do not handle read-only USB clocks appropriately before kernel version 3.10. Therefore with kernels prior to version 3.10 only the USB MIDI interface of the Axe-FX II will work. In order to get the USB audio interface of the Axe-FX II working, too, such kernels need to be patched or updated to at least version 3.10.

Important:
If the Axe-FX II has been powered up and connected via USB during the installation process, dis- and reconnect the USB cable or reboot the Axe-FX II in case it does not appear automatically as a USB audio and midi interface after running the script.

For uninstalling simply run axefx2setup.sh adding the option "-u" (without the quotes). As a second optional parameter the path to the udev rules file can be added, but typically this is not necessary.

The script has been written under openSUSE 11.4+ but should work with other LINUX distributions as well. Depending on your system it might be necessary to adjust the path for udev rules files and reload the udev rules manually.

No liability is taken for any damages that may be caused by using this script.

Have a lot of fun!
