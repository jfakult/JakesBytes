#!/bin/bash

MAX_BRIGHTNESS=$(brightnessctl max)
MIN_BRIGHTNESS=$(echo "$MAX_BRIGHTNESS * 0.1" | bc -l)

#echo "Max brightness: $MAX_BRIGHTNESS"
#echo "Min brightness: $MIN_BRIGHTNESS"

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
brightnessctl set -- "$1" >/dev/null && notify_user && brightnessctl get > /tmp/last_brightness && chown jake:jake /tmp/last_*

current_brightness=$(brightnessctl get)
#echo "Current brightness: $current_brightness"

# Also overlay software brightness
existing_gammastep_pids=$(pgrep -f "gammastep -l")

#echo $current_brightness

#pkill -f -9 "gammastep -l" > /dev/null

ps aux | grep gammastep | grep -v grep

# If user did not pass in "--no-gamma" flag
if [ "$2" = "--no-gamma" ]; then
	pkill -f -9 "gammastep -l" > /dev/null
else
	normalized_brightness=$(echo "scale=2; $current_brightness / $MAX_BRIGHTNESS" | bc -l)

	# clamp 0.1 to 1.0
	if (( $(echo "$normalized_brightness < $MIN_BRIGHTNESS / $MAX_BRIGHTNESS" | bc -l) )); then
		normalized_brightness=$(echo "scale=2; $MIN_BRIGHTNESS / $MAX_BRIGHTNESS" | bc -l)
	fi
	echo "Setting software brightness to $normalized_brightness"

	# Unfortunately gammastep doesn't have a reload option so we have to kill all previous instances
	# It also doesn't preempt, so we can't run 2 and kill the old one
	# Screen just flashes a bit while the program reloads, not too bad
	pkill -f -9 "gammastep -l" > /dev/null
	gammastep -l 0:0 -o -t 4500:4500 -P -b $normalized_brightness:$normalized_brightness & # 2>/dev/null &
fi

ps aux | grep gammastep | grep -v grep

echo "Existing gammastep pids: $existing_gammastep_pids"
echo "Current gammastep ids: $(pgrep -f "gammastep -l")"
# kill previous instances of gammastep
#if [ ! -z "$existing_gammastep_pids" ]; then
#	kill $existing_gammastep_pids
#fi

echo "done"