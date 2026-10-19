#!/bin/bash
# Emits maybar script-module tags: percent (int) and dimmed (bool, true when software dimming is on, per /tmp/software_dimmed written by set_brightness.sh)
# Event driven: refreshes on SIGUSR1 (sent by set_brightness.sh) and on backlight udev events

emit() {
	local percent dimmed
	percent=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')
	dimmed=$(cat /tmp/software_dimmed 2>/dev/null || echo false)
	printf 'percent|int|%s\ndimmed|bool|%s\n\n' "$percent" "$dimmed"
}

trap 'kill $sleeper 2>/dev/null' USR1
trap 'kill 0' EXIT

main=$$
udevadm monitor --udev --subsystem-match=backlight | while read -r _; do kill -USR1 $main; done &

emit
while true; do
	sleep infinity &
	sleeper=$!
	wait $sleeper
	emit
done
