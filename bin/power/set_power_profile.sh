#!/bin/bash

# Acceptable profiles: 'performance', 'balanced', 'power-save'

powerprofilesctl set $1

# if $2 exists, save it to /tmp/last_power_profile
if [ ! -z "$2" ]; then
    echo $2 > /tmp/last_power_profile
    chown jake:jake /tmp/last*
fi