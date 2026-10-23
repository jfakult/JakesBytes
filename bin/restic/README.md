# Laptop backup (restic -> NAS)

Backs up this laptop to a restic repo on the NAS, started automatically by a systemd timer.
No encryption (the repo password is empty; restic is always run with `--insecure-no-password`).

## Files

| File | Purpose |
|---|---|
| `backup_restic.sh` | The backup itself. Root only. |
| `backup_nag.sh` | Decides *when* to back up, runs it, nags when overdue. Root only (except `--test`, `--status`). |
| `include.txt` / `exclude.txt` | restic `--files-from` whitelist / `--exclude-file` list. |
| `wofi.css` | Template for the nag menu; colors come from `~/.config/system_styles.sh`. |

Systemd (in `/etc/systemd/system/`): `backup_nag.timer` runs `backup_nag.service` (this repo's
`backup_nag.sh`) 10 min after boot and then every 30 min.

## When it backs up (`backup_nag.sh`, every ~30 min)

1. Last backup under 1 day old: nothing.
2. Otherwise get a time estimate (`backup_restic.sh --estimate`, a dry run; a real estimate is cached 6h).
   - Estimate under 3 min: **backup runs automatically**, with notifications before/after.
   - Estimate unavailable (NAS or repo unreachable): a "Backup can't run" notification (at most every 4h);
     it is retried on the next run (failures are not cached).
3. Estimate 3 min or more (or unavailable) and last backup 3 days old or more: a notification plus a wofi menu:
   Run now / Ask me tomorrow / Ask me next week. Closing the menu asks again in an hour.

Every run logs why it did or didn't back up.

## What a backup does (`backup_restic.sh`)

1. Mounts `/mnt/NAS/Backup` (NFS from 192.168.1.199) if needed, and unmounts it afterwards if it mounted it.
   A failed mount exits with code 3.
2. Writes package manifests to `/var/backup-manifests/` (`pkglist.txt`, `aur.txt`, `services.txt`).
3. Runs `~/.config/prep_repo.sh` as jake and commits the `~/.config` git repo locally (no push).
4. Copies `proxmox-config`, `unraid-config`, `unraid-appdata` from `Butlah/` on the NAS mount to
   `/root/backup/` with rsync (`--delete`). A missing source is skipped; a failed copy only warns.
   `/root/backup` is excluded from the restic backup so it isn't copied back onto the NAS.
5. `restic backup` of `include.txt` minus `exclude.txt` to `/mnt/NAS/Backup/Framework`
   (tags `laptop`, host `framework`).
6. Prunes: keep 7 daily, 4 weekly, 12 monthly, 2 yearly. Prints repo stats.

Problems in steps 3 and 4 never fail the backup; they send a notification and continue.

## Commands

```
backup_nag.sh --status      # last backup (when, how long ago, duration, data sent, rate), next backup, snooze, timer. No root needed.
backup_nag.sh --test [SEC]  # show the real dialog with a fake estimate; never runs a backup. No root needed.
backup_nag.sh --watch       # follow the journal (also: backup_restic.sh --watch)
sudo backup_restic.sh       # run a backup now
sudo backup_restic.sh --estimate   # dry run: prints ESTIMATE_BYTES / ESTIMATE_SECONDS (-1 = unknown)
```

Restore, for example: `restic --insecure-no-password -r /mnt/NAS/Backup/Framework restore latest --target /tmp/restore`
(mount the share first). The pulled repos in `/root/backup/<name>` are complete restic repos too.

## State (`/var/lib/restic-backup/`)

- `last_success` (epoch), `last_summary`, `last_stats` (key=value; feeds `--status`)
- `nag/`: `next` (snooze until), `est` (cached estimate), `est.out`, `est_failures.log` (history of failed estimates),
  `auto.log` / `manual.log` (last automatic / menu-started run), `unreachable_notified`, `wofi.css`

## Notes

- Custom systemd units live in `/etc/systemd` (covered by `/etc`).
- `/opt` is mostly pacman-managed, so it isn't included; add specific dirs (e.g. Flashpoint) if hand-installed.
- `~/.config/prep_repo.sh` (packages/services/dotfiles into `~/.config/_packages`) is a second copy of the same data.
