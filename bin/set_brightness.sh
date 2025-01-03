#!/bin/bash

MIN_BRIGHTNESS=0.1

iDIR="$HOME/.config/mako/icons"

# Get brightness
get_brightness() {
	echo $(brightnessctl -m | cut -d, -f4 | grep -Po "\d+")
}

# Get icons
get_icon() {
	current=$(get_brightness)
	if   [ "$current" -le "20" ]; then
		icon="$iDIR/brightness-20.png"
	elif [ "$current" -le "40" ]; then
		icon="$iDIR/brightness-40.png"
	elif [ "$current" -le "60" ]; then
		icon="$iDIR/brightness-60.png"
	elif [ "$current" -le "80" ]; then
		icon="$iDIR/brightness-80.png"
	else
		icon="$iDIR/brightness-100.png"
	fi

    echo "$icon"
}

# Notify
notify_user() {
	notify-send -u low -c setting_overlay -h string:x-canonical-private-synchronous:sys-notify -h int:value:$(get_brightness) -i "$(get_icon)" " " #"$(get_brightness)"
}

# Set hardware brightness
brightnessctl set -- "$1" && notify_user && brightnessctl get > /tmp/last_brightness && chown jake:jake /tmp/last_*

current_brightness=$(echo "scale=2; (1-$MIN_BRIGHTNESS) * (($(brightnessctl get) / 255.0)) + $MIN_BRIGHTNESS" | bc -l)

# Also overlay software brightness
#gamma_pid=$(pgrep gammastep)


pkill -f -9 "gammastep -l"

# If user did not pass in "--no-gamma" flag
if [ "$2" = "--no-gamma" ]; then
	echo "Skipping software dimming"
else
	gammastep -l 0:0 -o -P -t 6500:6500 -b $current_brightness:$current_brightness 2>/dev/null &
fi
#sleep 1

#if [ -n "$gamma_pid" ]; then
#	kill $gamma_pid
#fi