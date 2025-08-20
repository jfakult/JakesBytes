#!/bin/bash

set -e

show_help() {
  echo "Usage: $0 <profile-name> [output-file]"
  echo
  echo "Generate a kanshi profile from the current Sway output configuration."
  echo
  echo "Arguments:"
  echo "  <profile-name>   Required. Name of the kanshi profile (e.g., 'docked', 'mobile')."
  echo "  [output-file]    Optional. File to write (default: kanshi-<profile-name>.conf)"
  echo
  echo "Example:"
  echo "  $0 docked"
  echo "  $0 mobile ~/.config/kanshi/config"
}

# Show help if requested or missing required args
if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then
  show_help
  exit 1
fi

PROFILE_NAME="$1"
mkdir -p ~/.config/kanshi
OUT_FILE="$HOME/.config/kanshi/config"
touch "$OUT_FILE"

# Check if "profile $PROFILE_NAME" already exists
if grep -q "^profile $PROFILE_NAME" "$OUT_FILE"; then
  echo "Profile '$PROFILE_NAME' already exists in $OUT_FILE."
  exit 1
fi

echo "profile $PROFILE_NAME {" >> "$OUT_FILE"

swaymsg -t get_outputs -r | jq -c '.[] | select(.active)' | while read -r output; do
  name=$(echo "$output" | jq -r '.name')
  transform=$(echo "$output" | jq -r '.transform')
  rect_x=$(echo "$output" | jq -r '.rect.x')
  rect_y=$(echo "$output" | jq -r '.rect.y')
  scale=$(echo "$output" | jq -r '.scale')
  scale_str=$( [[ "$scale" != "1" ]] && echo " scale $scale" || echo "" )

  echo "  output $name transform $transform position ${rect_x},${rect_y}$scale_str" >> "$OUT_FILE"
done

echo "}" >> "$OUT_FILE"
echo "" >> "$OUT_FILE"
echo "✅ Kanshi profile written to: $OUT_FILE"
