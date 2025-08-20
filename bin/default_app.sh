#!/bin/bash

if [ "$1" == "h" -o "$1" == "help" -o "$1" == "--help" -o "$1" == "-h" -o -z "$1" ]; then
    echo Usage:
    echo "default_app.sh {FILE_NAME}                 (Returns file type and default app for it)"
    echo "default_app.sh {FILE_NAME} {DEFAULT_APP}   (Sets default app)"
    echo "default_app.sh ls                           (Lists all .desktop files)"
    exit 0
fi

# if $1 == ls, list all the .desktop files
if [ "$1" == "ls" ]; then
    ls /usr/share/applications/*.desktop
    exit 0
fi

type=$(xdg-mime query filetype "$1")

if [ -n "$2" ]; then
    # Update default app
    xdg-mime default "$2" "$type"
else
    # Just print the default app
    echo "File type: $type"
    echo "Default Application:" $(xdg-mime query default $type)
fi
