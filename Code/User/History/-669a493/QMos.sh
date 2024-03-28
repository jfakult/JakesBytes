#!/bin/bash

# Abort if any command fails
set -e

uhoetn

echo "Be very careful with this script. It will install a lot of packages and overwrite things."
read -p "Do you want to continue? (y/n) " -n 1 -r
echo yes
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Aborting"
    exit 1
fi


################################################################################################


cd ~/.config/

read -p "Install yay aur manager? (y/n) " -n 1 -r

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