restic backup lists.

Pre-run: write package manifests (pacman equivalent of the dpkg/dnf approach)
  mkdir -p /var/backup-manifests
  pacman -Qqen > /var/backup-manifests/pkglist.txt
  pacman -Qqem > /var/backup-manifests/aur.txt
  systemctl list-unit-files | grep 'enabled$' | grep -v @ | awk '{print $1}' > /var/backup-manifests/services.txt

Run:
  restic backup --files-from ~/bin/restic/include.txt --exclude-file ~/bin/restic/exclude.txt

Notes:
- Custom systemd units live in /etc/systemd (covered by /etc).
- /opt is mostly pacman-managed, so not included; add specific dirs (e.g. Flashpoint) if hand-installed.
- ~/.config/prep_repo.sh == backup_jake_os.sh (packages/services/dotfiles into ~/.config/_packages, pushed to git). Still useful as a second copy.
