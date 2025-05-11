#!/bin/bash

# Only update the system after we have launched sway (/tmp/sway_launched)
# This gives the user the option to open other terminals, wait for wifi, etc.
if [ ! -f /tmp/sway_launched ]; then
    exit 0
fi

# If root and we haven't run this as root
if [ "$EUID" -eq 0 ] && [ ! -f /tmp/booted_root ]; then
    read -p "Fresh boot detected, update **root** system? [Y/n] " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]?$ ]]; then
        echo
        echo "Why you make-a me sad?"
        exit 0
    fi
    echo "Cleaning up orphaned packages..."
    pacman -Qdtq | pacman -Rns - 2>/dev/null
    touch /tmp/booted_root
fi

# if root and we have run this
if [ "$EUID" -eq 0 ] && [ -f /tmp/booted_root ]; then
    echo "Updating system..."

    kernel_needs_upgrade=$(pacman -Qu | grep linux)
    pacman -Syyu --noconfirm

    if [ -n "$kernel_needs_upgrade" ]; then
        echo "Kernel was upgraded during this update. USBs may not work until reboot."
        read -p "Reboot now? [Y/n] " -n 1 -r
        if [[ ! $REPLY =~ ^[Yy]?$ ]]; then
            echo
            echo "Your mother would be dissapointed in you."
            exit 0
        else
            echo "Rebooting in 3 seconds (ctrl-c to cancel)..."
            sleep 1
            echo 2
            sleep 1
            echo 1
            sleep 1
            reboot
        fi
    fi
fi

# If /tmp/booted exists, then the system has already been updated
if [ ! -f /tmp/booted ]; then
    read -p "Fresh boot detected, update **user** system? [Y/n] " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]?$ ]]; then
        echo
        echo "Your mother would be dissapointed in you."
        exit 0
    fi
    echo "Updating system..."

    sudo pacman -Sy
    kernel_needs_upgrade=$(pacman -Qu | grep linux)

    yay -Syyu --noconfirm --answerdiff=None --answeredit=None && touch /tmp/booted && chown jake:jake /tmp/booted
    
    if [ -n "$kernel_needs_upgrade" ]; then
        echo "Kernel was upgraded during this update. USBs may not work until reboot."
        read -p "Reboot now? [Y/n] " -n 1 -r
        if [[ ! $REPLY =~ ^[Yy]?$ ]]; then
            echo
            echo "Your mother would be dissapointed in you."
            exit 0
        else
            echo "Rebooting in 3 seconds (ctrl-c to cancel)..."
            sleep 1
            echo 2
            sleep 1
            echo 1
            sleep 1
            reboot
        fi
    fi
fi
