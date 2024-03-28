# My Arch configs

And some bootstrap helpers.

Run `setup.sh` to install the system. Assuming that a user with access to `sudo pacman -Syu` exists

### Documentation and Tutorials for System Setup

- [FPrint](https://wiki.archlinux.org/title/fprint)
    - Preffered addons: `pam-fprint-grosshack (aur)`

- [MakePkg (Optimizations)](https://wiki.archlinux.org/title/makepkg#Tips_and_tricks)
    - Preffered optimizations: `ccache`, `mold`, `parallel downloads`, `parallel compression`

- [Reflector](https://wiki.archlinux.org/title/reflector)
    - Enable systemd timer

- [Sudoers](https://man.archlinux.org/man/sudoers.5.en)
    - Recommendation is to set something like the following:
    - ```File: /etc/sudoers.d/jake 
    jake ALL=(ALL) /usr/bin/pacman -S *
    jake ALL=(ALL) /usr/bin/pacman -Syu
    jake ALL=(ALL) /usr/bin/pacman -U /home/jake/build/yay* *
    jake ALL=(ALL) /usr/bin/pacman -U --config /etc/pacman.conf -- /home/jake/.cache/yay/* *
    jake ALL=(ALL) /usr/bin/pacman -D *
    jake ALL=(ALL) /usr/bin/shutdown *```