#!/bin/sh

echo -e "Stupid simple/dangerous AXE-FX II installer for FreeBSD.\nIf you continue it's presumed you agree to the license."
echo -e "You will need to be root and should have already installed fxload.\n"
read -r -p "Continue? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
		cp -vf axefx2load.hex /usr/local/share/fxload/
		cp -vf fractal.conf /usr/local/etc/devd/
        ;;
    *)
		exit 1
        ;;
esac



