cd ~/.config
mkdir -p _packages
cd _packages

echo "Saving official and aur packages"
pacman -Qe > packages.txt
pacman -Qm > packages_aur.txt

echo "Saving enabled systemd services"
systemctl list-unit-files | awk '{print $1"\t\t\t\t\t"$2}' | grep "enabled$" | grep -v "@" | awk '{print $1}' > services.txt

cd ~/.config
echo "Saving bashrc and bin scripts"
cp ~/.bashrc .
cp -r ~/bin .
