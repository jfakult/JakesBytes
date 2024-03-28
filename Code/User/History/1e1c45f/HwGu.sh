#!/bin/bash

# Status can either be 'Charging' or 'Discharging'

if [ "$status" = "Charging" ]; then
    echo "Device is currently charging."
elif [ "$status" = "Discharging" ]; then
    echo "Device is currently discharging."
else
    echo "Unknown status."
fi