#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: $0 <brightness>"
	exit 1
fi

pid=$(pgrep gammastep)

gammastep -l 0:0 -b $1:$1 2>/dev/null &
sleep 0.1

if [ -n "$pid" ]; then
	kill $pid
fi
