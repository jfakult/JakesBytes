#!/bin/bash

# Get the app_id of the focused window
focused_app=$(swaymsg -t get_tree | jq '.. | select(.focused? == true).app_id')
focused_instance=$(swaymsg -t get_tree | jq '.. | select(.focused? == true).window_properties.instance')

# Check if the focused application is Chromium
if [[ "$focused_app" == *"chromium"* ]] || [[ "$focused_instance" == *"brave"* ]]; then
  # Use wtype to simulate the Ctrl+t key press
  wtype -M Ctrl t -m Ctrl
else #if [[ "$focused_app" == *"foot"* ]]; then
  # Move to window to the right
  wtype -M win s -m win
fi
