#!/bin/bash

##### Half dynamic / Half static setup for any special windows
### This might be repositioning windows we launch in floating mode or assigning a workspace to a window


###################### Variables ######################

spotify_workspace=4

# Assuming: 2560x1600
iwgtk_window_width=660
iwgtk_window_height=1000


# Kill any previous instances of this script excluding the current one
kill $(pgrep -f "setup_special_windows.sh" | grep -v ^$$\$) 2>/dev/null
pkill -f "swaymsg -t subscribe"
scale_factor=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .scale')

####################################################################################################

swaymsg "assign [title=\"Spotify Premium\"] workspace number $spotify_workspace"


##################### IWGTK SETUP #####################

iwgtk_window_width=$(echo "$iwgtk_window_width / $scale_factor" | bc)
iwgtk_window_height=$(echo "$iwgtk_window_height / $scale_factor" | bc)
bottom_offset=$(echo "35 / $scale_factor" | bc)
right_offset=$(echo "0 * $scale_factor" | bc)

screen_width=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .current_mode.width')
screen_height=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .current_mode.height')
x=$(echo "$screen_width / $scale_factor - $iwgtk_window_width - $right_offset / 1" | bc)
y=$(echo "$screen_height / $scale_factor - $iwgtk_window_height - $bottom_offset / 1" | bc)

# print everyithng nicely
echo $scale_factor
echo "screen_width: $screen_width"
echo "screen_height: $screen_height"
echo "iwgtk_window_width: $iwgtk_window_width"
echo "iwgtk_window_height: $iwgtk_window_height"
echo "x: $x"
echo "y: $y"

# Use swaymsg to setup the window for iwgtk
#swaymsg "for_window [app_id=\"iwgtk\"] floating enable, move position $x $y, resize set $iwgtk_window_width $iwgtk_window_height"
swaymsg "for_window [app_id=\"iwgtk\"] floating enable"

# Subscribe to new windows events and move them to the right position
swaymsg -t subscribe -m '["window"]' | jq --unbuffered -r '
  select(.change == "new" and .container.app_id == "iwgtk") | .container.id' |
  while read -r id; do
    swaymsg "[con_id=$id] resize set $iwgtk_window_width $iwgtk_window_height, move position $x $y"
  done &