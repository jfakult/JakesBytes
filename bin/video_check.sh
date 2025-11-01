#!/bin/bash

# file or list of files to check
VIDEO_FILE="$@"



if [ -z "$VIDEO_FILE" ]; then
  echo "Usage: $0 <video_file1> [<video_file2> ...]"
  exit 1
fi

for FILE in "$@"; do
  if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
  else
    echo "FFMPEG Error Check for $FILE"
    ffmpeg -hide_banner -v warning -stats -i "$FILE" -f null - | grep frame
  fi
done