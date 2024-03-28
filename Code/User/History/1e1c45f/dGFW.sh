#!/bin/bash

# Status can either be 'Charging' or 'Discharging'

# if /tmp/last_power_profile does not exist, create it
if [ ! -f /tmp/last_power_profile ]; then
    echo "balanced" > /tmp/last_power_profile
fi

if [ "$status" = "Charging" ]; then
    echo "Device is currently charging."
    current_profile=$(powerprofilectl get)
    if [ "$current_profile" = "performance" ]; then
        echo "Current power profile is performance."
        exit 0
    fi
    echo $current_profile > /tmp/last_power_profile
    ./set_power_profile.sh performance
elif [ "$status" = "Discharging" ]; then
    echo "Device is currently discharging."
    last_profile=$(cat /tmp/last_power_profile)
    ./set_power_profile.sh $last_profile
else
    echo "Unknown status."
fi