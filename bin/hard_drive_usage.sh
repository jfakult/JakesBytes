#!/bin/bash

# Print usage in percent (without the percent sign) of "/"

usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# format for maybar script
echo "usage|range:0-100|${usage}"
echo ""