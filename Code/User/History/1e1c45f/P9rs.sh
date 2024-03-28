#!/bin/bash

# Status can either be 'Charging' or 'Discharging'

if [ "$status" = "Charging" ]; then
    echo "Device is currently charging."
    current_profile=$(powerprofilectl get)
    echo $current_profile > /tmp/last_power_profile
    ./set_power_profile.sh performance
elif [ "$status" = "Discharging" ]; then
    echo "Device is currently discharging."
else
    echo "Unknown status."
fi