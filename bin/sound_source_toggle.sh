#!/bin/bash

source ~/.config/system_styles.sh

layouts=("us:''" "us:dvorak")

sinks=$(pactl list short sinks | awk '{print $2}')
#echo "Sinks: $sinks"
current_sink=$(pactl get-default-sink)
next_sink=$(echo "$sinks" | grep -A 1 "$current_sink" | sed -n 2p)

# If no sink, set to first sink
if [ -z "$next_sink" ]; then
    echo "No sink found, setting to first sink"
    next_sink=$(echo "$sinks" | head -n 1)
fi

# Apply the sink change
#echo "Switching to sink $next_sink"
pactl set-default-sink "$next_sink"

# Build the notification message
notification_message=""
for sink in $(echo $sinks); do
    echo "Sink: $sink"
    # Friendly names and comparison keys
    # Capitalize the layout name for the notification
    friendly_name=$(echo "  "$sink | sed "s/alsa_output.//" | sed "s/_/ /g" | sed "s/-/ /g" | sed "s/.analog-stereo//")
    # Pad the output
    echo "Friendly name: $friendly_name"
    length=${#friendly_name}

    # Calculate how much padding is needed
    padding_needed=$((80 - length))

    # If padding is needed, append spaces to the end of the variable
    if [ $padding_needed -gt 0 ]; then
        printf -v friendly_name "%-${padding_needed}s" "$friendly_name"
    fi

    # Ensure the variable is exactly 40 characters by trimming or padding
    friendly_name=${friendly_name:0:40}
    echo "padded friendly name: $friendly_name"

    # Check if this is the current layout
    if [[ "$sink" == *"$next_sink"* ]]; then
        # Highlight the current layout
        text_color="$COLOR_DARK_TEXT"
        background_color="$COLOR_DARK_BACKGROUND_ALT"
    else
        text_color="$COLOR_DARK_TEXT_ALT" # Add some transparency to make it looks semi-disabled
        background_color="$COLOR_DARK_BACKGROUND"
    fi


    notification_message+="<span color='$text_color' background='$background_color' \
    line-height='3'>$friendly_name</span>\n"
done

#echo "$notification_message"

# Send the notification
notify-send " " "$notification_message" --category=toggle_wide -h string:x-dunst-stack-tag:toggle
