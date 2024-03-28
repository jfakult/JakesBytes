#!/bin/bash

# Abort if any command fails
set -e


cd ~/.config/


# Install yay
./bin/update_aur

# Install all packages
yay -S - < _packages/packages.txt
yay -S - < _packages/packages_aur.txt


# Install executables
mkdir ~/bin
cp bin/* ~/bin
chmod -R u+x ~/bin/

cp .bashrc ~/.bashrc