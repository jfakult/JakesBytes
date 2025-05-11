# Print usage in percent (without the percent sign) of "/"

#!/bin/bash

usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# format for yambar script
echo "usage|range:0-100|${usage}"
echo ""