#!/bin/bash
#
# Shell script to install or uninstall the firmware file which has to be uploaded to the USB chip of the
# Fractal Audio Systems Axe-Fx II (Original, Mark II, XL and XL+) via fxload,
# and to create, modify or delete the udev rules file which runs fxload each time an Axe-Fx II is connected to a USB port.
#
# (C) Joachim Gahl - 29.12.2011; 02.11.2012; 17.02.2013; 21.09.2015; 17.10.2015; 10.04.2016; 12.08.2016
# Modified by Jamie Drinkell - 09.06.2024; 23.01.2026
#

# ScriptVersion
version='1.08'

# ScriptLocation
my_path="$(dirname "$(readlink -f "$0")")"  # absolute path to the location where this script has been stored to.

# SourceFiles
axefx2loadFW=axefx2load.hex		  # firmware file to be uploaded to the USB chip of the Axe-Fx II
udev_rules=55-fractalaudio.rules  # udev rules file for Fractal Audio Systems devices which gets filled with a rule (see 'axefx2_rule' below) to run fxload when an Axe-Fx II is connected via USB

# DestinationDirs
axefx2loadFW_dir=/usr/share/usb/FractalAudio/axefx2	 # directory to store firmware for use with fxload
udev_rules_dir=/etc/udev/rules.d					 # directory of udev rules

# Rules file header
header='# fractalaudio.rules - udev rules for uploading USB firmware to Fractal Audio Systems devices'

# Text attributes
bold=`tput bold`
normal=`tput sgr0`

# Messages
fail_msg='Installation failed. Press any key...'
cancel_msg='Installation cancelled. Press any key...'

# Functions #
request ()
{
	echo -e $1
	read -n 1 -s answer
}

check_root ()
{
	# test if script is run with root permissions
	if [[ $(id -u) -ne 0 ]]; then
		request "\naxefx2setup.sh needs to be run with root permissions.\n\n\n$1"
		exit 1
	fi
}

get_fxload_path ()
{
	read -e -i "$fxload_path" -p "" answer
	until [ -f $answer ] && [ ! ${#answer} -eq 0 ]; do
		echo -e "\nThe specified path or file does not exist. Press [y] if you would like to enter another path to fxload or press any other key to cancel."
		read -n 1 -s answer
		case $answer in
		"y"|"Y")
			echo -e "\nPlease enter the complete path to fxload including the binary's name: "
			read answer
			;;
		 *)
			request "\n\n$cancel_msg"
			exit 0
			;;
		esac
	done
	fxload_path="$answer"
}

reload_udevrules ()
{
	# the command to reload udev rules can vary between different LINUX distributions, so
	# if it fails the user will have to restart udev or the computer to refresh udev
	udevadm control --reload-rules
	if [ $? -ne 0 ]; then
		echo -e "\nThe command ${bold}udevadm control --reload_rules${normal} to reload the udev rules failed. Please restart your computer."
	else
        # silently check if the Axe-Fx II is connected (and not recognized as USB audio and midi interface);
		lsusb -d 2466:0003 >/dev/null
		if [ $? -eq 0 ]; then  # in that case:
			# trigger the new udev rule in order to get the udev rule executed without rebooting or dis-/reconnecting the Axe-Fx II
			udevadm trigger --action=add --subsystem-match=usb --attr-match=idVendor=2466 --attr-match=idProduct=0003
			if [ $? -ne 0 ]; then  # only if it fails
			    # the user will have to reboot or dis-/reconnect the Axe-Fx II
				echo -e "\nPlease reboot your Fractal Audio Systems Axe-Fx II or dis- and reconnect the USB cable."
			fi
		fi
	fi
}

# Main #
case $1 in

# option "-u": uninstall
"-u")
	echo -e "\n${bold}Uninstall Fractal Audio Systems USB Bootloader${normal}\n"
	check_root "Uninstalling failed. Press any key..."
	request "\nPress [y] to remove the Fractal Audio Systems Axe-Fx II bootloader firmware and udev rules file or press any other key to cancel."

	case $answer in
	"y"|"Y")
		rm -r "$axefx2loadFW_dir"					                 # delete directory with firmware for Axe-Fx II
		if [ `ls -a "${axefx2loadFW_dir%/*}" | wc -l` -le 2 ]; then	 # (only) if the directory /usr/share/usb/FractalAudio is emtpy,
			rm -r "${axefx2loadFW_dir%/*}"				             # also delete directory /usr/share/usb/FractalAudio
		fi

		if [ ! ${#2} -eq 0 ]; then					          # if next to the option -u a second parameter has been passed,
			udev_rules_dir=$2					              # set this parameter's content as the udev rules dir;
		elif [ -f "$my_path"/uninstinf ]; then				  # else look for an uninstall information file (uninstinf)
			udev_rules_dir=$(sed -n 8p "$my_path"/uninstinf)  # and extract the udev rules dir from there
		fi

        # test if the udev rules file exists in the udev rules directory
		until [ -f $udev_rules_dir/$udev_rules ]; do
			request "\nThe udev rules file ${bold}$udev_rules${normal} has not been found. Press [y] to proceed with entering the appropriate path or press any other key to skip this file."

			case $answer in
			"y"|"Y")
				echo -e "\nPlease enter the complete path to the udev rules file ${bold}$udev_rules${normal}: "
				read udev_rules_dir
				if [ "${udev_rules_dir:(-1)}" == "/" ]; then	                # if entered path ends with "/"
					udev_rules_dir=${udev_rules_dir:0:${#udev_rules_dir} - 1}	# remove last "/" for further processing
				fi
				;;

			*)
				if [ -f "$my_path"/uninstinf ]; then  # if an uninstall information file exists,
					rm "$my_path"/uninstinf	          # delete it
				fi

				request "\n\nUninstalling finished. Press any key..."
				exit 0
				;;
			esac
		done

		if ( grep -q "$header" "$udev_rules_dir/$udev_rules" ) && ( grep -q "# <Fractal Audio Systems Axe-FX II>" "$udev_rules_dir/$udev_rules" ) && ( grep -q 'ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2466", ATTR{idProduct}=="0003", RUN+=' "$udev_rules_dir/$udev_rules" ); then
			if [ `wc -l < $udev_rules_dir/$udev_rules` -eq 4 ]; then	# if udev rules file contains the Axe-Fx II entry only
				rm "$udev_rules_dir/$udev_rules"		# delete udev rules file
			else							# otherwise ask...
				request "\nThe file ${bold}$udev_rules${normal} is queued for deletion but has been altered. There might be another Fractal Audio Systems device still needing this file.\n\nPress [y] to delete it nevertheless, [m] to modify or any other key to keep it."
				case $answer in
				"m"|"M")					# choice "m": keep but modify the udev rules file content
					echo -e "\nRemoving Axe-Fx II related entries from $udev_rules..."
					l=$(grep -n "# <Fractal Audio Systems Axe-FX II>" "$udev_rules_dir/$udev_rules")
					let start=${l%:*}-1
					let end=${l%:*}+1
					sed -i ""$start,$end"d" "$udev_rules_dir/$udev_rules"
					;;
				"y"|"Y")					# choice "y": delete udev rules file
					echo -e "\nDeleting $udev_rules..."
					rm "$udev_rules_dir/$udev_rules"
					;;
				*)						# choice "any other key": do nothing
					echo -e "\nKeeping $udev_rules..."
					;;
				esac
			fi
			if [ -f "$my_path"/uninstinf ]; then	# if an uninstall information file exists,
				rm "$my_path"/uninstinf				# delete it
			fi
			reload_udevrules					# reload udev rules
			request "\n\nUninstalling finished. Press any key..."
		fi
		;;

	# Cancel the install
	*)
		request "\n\nUninstalling cancelled. Press any key..."
		;;
	esac
	;;

# option "-v": show version information
"-v")
	request "\nVersion: "$version"\n\nPress any key..."
	;;

# option "-h": show help information
"-h"|"--help")
	request "\nRunning this script without any option installs the Fractal Audio Systems USB bootloader firmware and udev rules files for the Axe-Fx II (Original, Mark II, XL and XL+).\n\nAdditionally fxload (http://sourceforge.net/projects/linux-hotplug/files/fxload/) is required to upload the firmware to the USB chip of the Fractal Audio Systems Axe-Fx II each time it is connected via USB. This script will NOT install fxload!\n\nOptions:\n\t-u\t\tUninstall - removes the bootloader and udev rules files.\n\t\t\tThe path to the udev rules files can be passed as a second optional parameter.\n\t-v\t\tShows version info.\n\t-h or --help\tShows this text.\n\n${bold}Note:${normal} Install as well as uninstall actions require root permissions.\n\nPress any key..."
	;;

# no or invalid option: install files
*)
	echo -e "\n${bold}Install Fractal Audio Systems USB Bootloader${normal}\n"
	check_root "$fail_msg"

	# test if license text file exists
	if [ ! -f "$my_path"/License ]; then
		request "\nThe license text file has not been found.\n\n\n$fail_msg"
		exit 1
	fi

	# test if bootloader firmware file exists
	if [ ! -f "$my_path"/$axefx2loadFW ]; then
		request "\nThe bootloader firmware file ${bold}$axefx2loadFW${normal} has not been found.\n\n\n$fail_msg"
		exit 1
	fi

    # search for the path to the fxload binary
	fxload_path=$(whereis -b fxload)
	fxload_path="${fxload_path#*:}"
	fxload_path=${fxload_path:1:${#fxload_path}}

	# if fxload was not found by whereis, ask for it's path or failing that, cancel.
	if [ ${#fxload_path} -eq 0 ]; then
		request "\nTo upload the firmware to the USB chip of the Axe-Fx II fxload (http://sourceforge.net/projects/linux-hotplug/files/fxload/) is required.\n\n${bold}fxload${normal} has not been found.\n\nPress [y] if you would like to enter the path to fxload or press any other key to cancel."
		case $answer in
		"y"|"Y")
			echo -e "\nPlease enter the complete path to fxload including the binary's name: "
			get_fxload_path
			;;
		*)
			request "\n\n$cancel_msg"
			exit 0
			;;
		esac
	fi

	# Get Kernel Info
	kvers=$(uname -r|cut -f1 -d'.')	  # get kernel version
	kmajor=$(uname -r|cut -f2 -d'.')  # get kernel major revision
	kminor=$(uname -r|cut -f3 -d'.')  # get kernel minor revision

	# test if kernel is older than version 3.10
	if ( [ ${kvers} -lt 3 ] )  || ( ( [ ${kvers} -eq 3 ] ) && ( [ ${kmajor} -lt 10 ] )  ); then
		# test if kernel is at least 2.6.35 (UAC2 compliance)
		if ( [ ${kvers} -lt 2 ] )  || ( ( [ ${kvers} -eq 2 ] ) && ( [ ${kmajor} -lt 6 ] ) || ( ( [ ${kmajor} -eq 6 ] ) && ( [ ${kminor%%[^0-9]*} -lt 35 ] ) ) ); then
		      echo -e "\n${bold}WARNING:${normal} The USB audio interface of the Axe-Fx II needs a UAC2 compliant kernel. The present kernel seems to be too old but *may* support the USB MIDI interface of the Axe-Fx II."
		else
		      echo -e "\n${bold}WARNING:${normal} The present kernel supports the USB MIDI interface of the Axe-Fx II. Since this kernel presumably does not handle read-only USB clocks appropriately, the USB audio interface of the Axe-Fx II will not work until the kernel has been patched or updated to at least version 3.10."
		fi

		# Does the user want to continue despite possible issues due to the old kernel?
		request "\nPress [i] to continue the installation process nonetheless or press any other key to cancel.\n"
		case $answer in
		"i"|"I")
			echo -e "\nContinuing...\n"
		;;
		*)
			request "\n$cancel_msg"
			exit 0
		;;
		esac
	fi

	# Show Fractal Audio Systems License Agreement
	request "\nThe USB firmware file ($axefx2loadFW) to be used originates from Fractal Audio Systems. Press any key to show the Fractal Audio Systems Axe-Fx Software License Agreement. After reading it press [q].\n"
	less "$my_path"/License
	cat "$my_path"/License
	request "\n\nPress [y] to accept the Fractal Audio Systems Axe-Fx Software License Agreement or press any other key to cancel."

	case $answer in

	# Go ahead and install
	"y"|"Y")
		# test if the path to udev rules files exists
		until [ -d $udev_rules_dir ]; do
			request "\nThe path ${bold}$udev_rules_dir/${normal} to the udev rules files has not been found. Press [y] to proceed with entering the appropriate path or press any other key to cancel."
			case $answer in
			"y"|"Y")
				echo -e "\nPlease enter the complete path to the udev rules files on your system: "
				read udev_rules_dir
				if [ "${udev_rules_dir:(-1)}" == "/" ]; then	# if entered path ends with "/"
					udev_rules_dir=${udev_rules_dir:0:${#udev_rules_dir} - 1}	# remove last "/" for further processing
				fi
				;;
			*)
				request "\n\n$cancel_msg"
				exit 0
				;;
			esac
		done

		# if more than one fxload binary has been found...
		if [[ ${fxload_path/fxload} == */fxload ]]; then
			echo -e "\nTo upload the firmware to the USB chip of the Axe-Fx II fxload is required. fxload has been found in multiple locations, so you have to choose one of them:\n\n"$fxload_path"\n\nPress [Return] to acknowledge the preselected first entry or enter the complete path to the desired fxload including the binary's name: "
			fxload_path=${fxload_path%% *}  # preselect the location found at first
			get_fxload_path
		fi

		# Store the Axe-FX Binary in an appropriate place
		mkdir -m 755 -p "$axefx2loadFW_dir"	 # create directory /usr/share/usb/FractalAudio/axefx2 and make it readable for everybody
		chmod 755 "${axefx2loadFW_dir%/*}"	 # make directory /usr/share/usb/FractalAudio readable for everybody as well
		cp "$my_path/$axefx2loadFW" "$axefx2loadFW_dir"
		# Did copying fail?
		if [ $? -gt 0 ]; then
			request "\nFailed to copy the binary\n$fail_msg"
			exit 1
		fi

		# make firmware file readable for everybody
		chmod 644 "$axefx2loadFW_dir/$axefx2loadFW"

		# Check if Fractal Audio udev rules file exists, then ask if it should be replaced
		if [ -f "$udev_rules_dir/$udev_rules" ]; then
			echo -e "\n\nThe udev file ${bold}$udev_rules_dir/$udev_rules${normal} is already present. It has not been checked."
			request "Would you like to replace it? Press [y] to process or any other key to abort without modifying the udev rules."
			case $answer in
			"y"|"Y")
				rm "$udev_rules_dir/$udev_rules" # Remove the old udev rule
				;;
			*)
				request "\nAborting without modifying udev rules...\n$fail_msg"
				exit 0
				;;
			esac
		fi

		# Make a new udev rule
		echo -e $header > "$udev_rules_dir/$udev_rules"	 # create udev rules file with header
		if [ $? -gt 0 ]; then
			request "\n$fail_msg"
			exit 1
		fi
		chmod 644 "$udev_rules_dir/$udev_rules"			# make udev rules file user readable

		# Grab the error message
		# Redirect stderr to stdout using 2>&1
		help_response=$(fxload 2>&1)

		# Set the udev rule depending on fxload version
		if [[ $help_response == *"-D"* ]]; then
			axefx2_rule='\n# <Fractal Audio Systems Axe-FX II>\nACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2466", ATTR{idProduct}=="0003", RUN+="'$fxload_path' -t fx2lp -I '$axefx2loadFW_dir/$axefx2loadFW' -D $env{DEVNAME}"'
		# Write the udev rule for the newer fxload (-D replaced with -p)
		elif [[ $help_response == *"-p"* ]]; then
			axefx2_rule='\n# <Fractal Audio Systems Axe-FX II>\nACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2466", ATTR{idProduct}=="0003", RUN+="'$fxload_path' -t fx2lp -I '$axefx2loadFW_dir/$axefx2loadFW' -p $env{BUSNUM},$env{DEVNUM}"'
		fi

		# write Axe-Fx II section into udev rules file
		echo -e $axefx2_rule >> "$udev_rules_dir/$udev_rules"
		if [ $? -gt 0 ]; then
			request "\n$fail_msg"
			exit 1
		fi

		reload_udevrules  # reload udev rules to get the Fractal Audio Systems rule recognized

		# create uninstall information file
		echo -e "#\n# DO NOT EDIT THIS FILE\n#\n# It has been automatically generated by axefx2setup.sh.\n# Note: This file needs to be in the same path as axefx2setup.sh!\n#\n\n"$udev_rules_dir > "$my_path"/uninstinf
		request "\n\nInstallation finished. Press any key..."
		;;

	# Did not accept the license agreement, cancel...
	*)
		request "\n\n$cancel_msg"
		;;
	esac
	;;
esac
