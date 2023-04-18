#!/bin/bash
# vim: ts=4 sw=4 noet

if [[ -n $1 ]]; then
	# debug
	set -x
fi

# Get the user name by UID
# Search for the user with UID from 1000 to 1010
# Use the first one found
for i in {1000..1010}; do
	USER=$(id -nu "$i")
	if [[ -n $USER ]]; then
		break
	fi
done

SETTINGS="/home/${USER}/.config/udev_hotplug/settings.sh"

if [[ -f "${SETTINGS}" ]]; then
	source "${SETTINGS}"

	if [[ -z "$EXTERNAL_RESOLUTION" ]]; then
		EXTERNAL_RESOLUTION=""$EXTERNAL_RESOLUTION""
	fi

	if [[ -z "$INTERNAL_RESOLUTION" ]]; then
		INTERNAL_RESOLUTION=""$EXTERNAL_RESOLUTION""
	fi
fi

function display_by_name() { xrandr | grep -o -P "(?i)($1.+?[0-9])"; }

#Adapt this script to your needs.
DEVICES=(/sys/class/drm/*/status)
DEVICES+=(/tmp/JACK)
DEVICES+=(/proc/acpi/button/lid/*/state)
DEVICES+=(/sys/class/power_supply/AC/online)

#inspired by /etc/acpd/lid.sh and the function it sources
_display=$(find /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##)
export DISPLAY=":${_display}.0"

# from https://wiki.archlinux.org/index.php/Acpid#Laptop_Monitor_Power_Off
_xauthority=$(ps -C Xorg -f --no-header | sed -n 's/.*-auth //; s/ -[^ ].*//; p')
export XAUTHORITY=${_xauthority}

# this while loop declare connected devices, exemple:
# ${HDMI1}
# ${VGA1}
# ${eDP}
# ${DP1}
# ${AC}
# ${JACK}

# All other display will be declared too

# The variable 'is_usb_dev' will be defined in settings:
# ${is_usb_dev}
# if this variable is not necessary, in settings, turn ATENTION_TO_USB_HID to:
# ATENTION_TO_USB_HID=true

for DEVPATH in "${DEVICES[@]}"; do
	if [[ ${DEVPATH} == *"JACK"* ]]; then
		DIR=$(basename "${DEVPATH}");
		STATUS=$(cat "${DEVPATH}");
		DEV="${DIR}";
	elif [[ ${DEVPATH} =~ LID|AC ]]; then
		DIR=$(basename "$(dirname "${DEVPATH}")");
		STATUS=$(cat "${DEVPATH}");
		DEV="${DIR}";
	else
		DIR=$(dirname "${DEVPATH}");
		STATUS=$(cat "${DEVPATH}");
		DEV=$(echo "${DIR}" | cut -d- -f 2-);
	fi
	ISHDMI=$(echo "${DEV}" | grep -i 'HDMI')

	if [[ -n "${ISHDMI}" ]]; then
		#REMOVE THE -X- part from HDMI-X-n
		DEV=HDMI${DEV#HDMI-?-}
	else
		DEV=$(echo "${DEV}" | tr -d '-')
	fi

	if [[ "connected" == "${STATUS}" ]]; then
		logger "${DEV} connected"
		declare "${DEV}=yes";
	elif [[ "${STATUS}" == "state:      open" ]]; then
		logger "${DEV} connected"
		declare "${DEV}=yes";
	elif [[ "${STATUS}" == 1 ]]; then
		logger "${DEV} connected"
		declare "${DEV}=yes";
	fi
done

if [[ -n "${HDMI1}" && -n "${VGA1}" ]]; then
	logger "HDMI1 and VGA1 are plugged in"
	# if usb device is connected
	if [[ -n ${is_usb_dev} ]]; then
		xrandr --output "$(display_by_name VGA)" --mode "$EXTERNAL_RESOLUTION" --primary
		xrandr --output "$(display_by_name HDMI)" --off
	else
		xrandr --output "$(display_by_name HDMI)" --mode "$EXTERNAL_RESOLUTION" --primary
		xrandr --output "$(display_by_name VGA)" --off
	fi
elif [[ -z "${VGA1}" && -n "${HDMI1}" ]]; then
	logger "HDMI1 is plugged in, but not VGA"
	xrandr --output "$(display_by_name VGA)" --off
	xrandr --output "$(display_by_name HDMI)" --mode "$EXTERNAL_RESOLUTION" --primary
elif [[ -n "${VGA1}" && -z "${HDMI1}" ]]; then
	logger "VGA1 is plugged in, but not HDMI"
	xrandr --output "$(display_by_name HDMI)" --off
	xrandr --output "$(display_by_name VGA)" --mode "$EXTERNAL_RESOLUTION" --primary
else
	logger "No external monitors are plugged in"
	xrandr --output "$(display_by_name eDP)" --mode "$INTERNAL_RESOLUTION" --primary
	xrandr --output "$(display_by_name VGA)" --off
	xrandr --output "$(display_by_name HDMI)" --off
	xrandr --output "$(display_by_name DP)" --off
fi
