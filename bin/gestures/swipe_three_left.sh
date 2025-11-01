#!/bin/bash

# Get the app_id of the focused window
focused_app=$(swaymsg -t get_tree | jq '.. | select(.focused? == true).app_id')
focused_instance=$(swaymsg -t get_tree | jq '.. | select(.focused? == true).window_properties.instance')

#echo "Focused app: $focused_app"
#echo "Focused instance: $focused_instance"

# Check if the focused application is Chromium, or instance is brave
if [[ "$focused_app" == *"chromium"* ]] || [[ "$focused_instance" == *"brave"* ]]; then
  echo 1
  # Use wtype to simulate the Ctrl+W key press
  wtype -M Ctrl w -m Ctrl
else #if [[ "$focused_app" == *"foot"* ]]; then
  # Move to window to the left
  wtype -M win h -m win
fi
