#!/bin/bash

# Abort if any command fails
set -e

function prompt_or_quit {
    read -p "$1 (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Aborting"
        exit 1
    fi
}

echo "Be very careful with this script. It will install a lot of packages and overwrite things."
prompt_or_quit "Do you want to continue?"


################################################################################################


cd ~/.config/

# Install yay
prompt_or_quit "Install yay aur manager?"
./bin/update_aur



# Install all packages
prompt_or_quit "Install all packages?"
yay -Syyu - < _packages/packages.txt
yay -S - < _packages/packages_aur.txt


# Install executables
prompt_or_quit "Install executables?"
mkdir ~/bin
cp bin/* ~/bin
chmod -R u+x ~/bin/


# Copy .bashrc
prompt_or_quit "Install .bashrc?"
cp .bashrc ~/.bashrc


# Download and install sway tools
mkdir -p ~/build
cd ~/build
prompt_or_quit "Install sway tools (~/build/swayos)?"
git clone git@github.com:jfakult/swayos.git
cd swayos
chmod u+x setup_arch.sh
./setup_arch.sh


cd ~/.config/