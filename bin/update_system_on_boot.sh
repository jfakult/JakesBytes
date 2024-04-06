#!/bin/bash

# If root and we haven't run this as root
if [ "$EUID" -eq 0 ] && [ ! -f /tmp/booted_root ]; then
    echo "Cleaning up orphaned packages..."
    pacman -Qdtq | pacman -Rns - 2>/dev/null
    touch /tmp/booted_root
fi

# If /tmp/booted exists, then the system has already been updated
if [ ! -f /tmp/booted ]; then
    echo "Updating system..."
    yay -Syyu && touch /tmp/booted
fi