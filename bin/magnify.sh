#!/bin/bash

DEFAULT_SCALE_FACTOR=1.5

FOCUSED_OUTPUT=$(swaymsg -t get_outputs --raw | jq '. | map(select(.focused == true)) | .[0].name' -r)
if [ -z "$FOCUSED_OUTPUT" ]; then
    echo "No focused output found"
    exit 1
fi

SCALE_FACTOR=$(swaymsg -t get_outputs --raw | jq ".[] | select(.name == \"$FOCUSED_OUTPUT\") | .scale" -r)

if [ -z "$SCALE_FACTOR" ]; then
    echo "No scale factor found for output $FOCUSED_OUTPUT"
    exit 1
fi

SIZE_STEP=0.1

if [ "$1" == "+" ]; then
    SCALE_FACTOR=$(echo "$SCALE_FACTOR + $SIZE_STEP" | bc)
elif [ "$1" == "-" ]; then
    SCALE_FACTOR=$(echo "$SCALE_FACTOR - $SIZE_STEP" | bc)
elif [ "$1" == "0" ]; then
    # Reset to default scale factor
    SCALE_FACTOR=$DEFAULT_SCALE_FACTOR
# help
elif [ "$1" == "h" -o "$1" == "help" -o "$1" == "--help" -o "$1" == "-h" ]; then
    echo "Usage: magnify.sh [+-0]"
    echo "  +: Increase scale factor"
    echo "  -: Decrease scale factor"
    echo "  0: Reset scale factor to default ($DEFAULT_SCALE_FACTOR)"
    exit 0
else
    echo "Output: $FOCUSED_OUTPUT"
    echo "Scale: $SCALE_FACTOR"
    exit 0
fi

if [ $(echo "$SCALE_FACTOR < 0.5" | bc) -eq 1 ]; then
    SCALE_FACTOR=0.5
fi
if [ $(echo "$SCALE_FACTOR > 4.0" | bc) -eq 1 ]; then
    SCALE_FACTOR=4.0
fi

echo "Output: $FOCUSED_OUTPUT"
echo "Scale: $SCALE_FACTOR"

swaymsg output "$FOCUSED_OUTPUT" scale $SCALE_FACTOR
