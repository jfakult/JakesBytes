#!/bin/bash

mkdir -p $HOME/Documents/Screenshots/Recordings
SDIR="$HOME/Documents/Screenshots/Recordings"
# yyyy-mm-dd-hh:mm:ss
date_str=$(date +%Y-%m-%d-%H:%M:%S)
mode="stop"
if [ -n "$1" ]; then
	mode="$1"
fi

if [ "$mode" == "start" ]; then
	pkill -f "wf-recorder"
	notify-send -h string:x-canonical-private-synchronous:sys-notify "Recording started"
	wf-recorder -f $SDIR/$date_str.mp4
elif [ "$mode" == "stop" ]; then
	notify-send -h string:x-canonical-private-synchronous:sys-notify "Recording stopped: $date_str.mp4"
	pkill -f "wf-recorder"
elif [ "$mode" == "toggle" ]; then
	pid=$(pgrep -x "wf-recorder")
	if [ -n "$pid" ]; then
		pkill -f "wf-recorder"
		notify-send -h string:x-canonical-private-synchronous:sys-notify "Recording stopped: $date_str.mp4"
	else
		notify-send -h string:x-canonical-private-synchronous:sys-notify "Recording started"
		wf-recorder -f $SDIR/$date_str.mp4
	fi
else
	echo "Invalid mode: $mode"
	echo "Valid modes: start, stop, toggle"
	exit 1
fi