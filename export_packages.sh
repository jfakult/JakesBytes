cd ~/.config
mkdir -p _packages
cd _packages

pacman -Qe > packages.txt
pacman -Qm > packages_aur.txt

systemctl list-unit-files | awk '{print $1"\t\t\t\t\t"$2}' | grep "enabled$" | grep -v "@" | awk '{print $1}' > services.txt