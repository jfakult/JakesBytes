#!/usr/bin/env bash
# Restic backup of this laptop to the NAS. Must be run as root.
# Usage: backup_restic.sh [--estimate]
#   --estimate  dry run only; prints "ESTIMATE_BYTES=<n>" and "ESTIMATE_SECONDS=<n>" (-1 = unknown)
# Lists: include.txt / exclude.txt next to this script.
set -euo pipefail

usage() {
  cat <<'USAGE'
backup_restic.sh - restic backup of this laptop to the NAS (no encryption, empty repo password)

Usage: sudo backup_restic.sh [--estimate | --watch | -h | --help]

  (no args)    Run a full backup, prune old snapshots, print repo stats.
  --estimate   Dry run only. Prints ESTIMATE_BYTES=<n> and ESTIMATE_SECONDS=<n>
               (-1 = unknown, e.g. no repo yet). Assumes ~500 Mbit on the LAN,
               ~10 Mbit if the NAS is reached over tailscale/WAN.
  -w, --watch, -f
               Follow the journal for backup_nag.service (last 50 lines, then live),
               which is where timer-run backups log. Doesn't need root. Ctrl-C to stop.
  -h, --help   Show this help.

Before backing up it copies the PVE config and the Unraid config/appdata restic repos from
the NAS mount (Butlah/<name>) into /root/backup with rsync (excluded from the restic backup).
Pull failures only warn.
Before backing up it also runs ~/.config/prep_repo.sh as jake, then commits the
~/.config git repo locally (dated message; failures only warn). It does not push.
Must be run as root. Mounts /mnt/NAS/Backup if needed and unmounts it again when
done (only if this script mounted it). Repo: /mnt/NAS/Backup/Framework.
Lists:  include.txt / exclude.txt next to this script.
A failed NAS mount exits with code 3. --estimate doesn't write the package manifests.
State:  /var/lib/restic-backup/ (last_success, last_summary, last_stats)
Keeps:  7 daily, 4 weekly, 12 monthly, 2 yearly snapshots.
USAGE
}
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -w|--watch|-f) exec journalctl -u backup_nag.service -n 50 -f ;;
  ""|--estimate) ;; *) usage >&2; exit 2 ;; esac

if [[ $EUID -ne 0 ]]; then
  echo "!!!  This script must be run as root  !!!"
  exit 1
fi

HERE="$(dirname "$(readlink -f "$0")")"
MNT="/mnt/NAS/Backup"
NAS_HOST="192.168.1.199"
NAS="$NAS_HOST:/mnt/user/Backup"
MANIFESTS="/var/backup-manifests"
STAMP_DIR="/var/lib/restic-backup"
KEEP=(--keep-daily 7 --keep-weekly 4 --keep-monthly 12 --keep-yearly 2)

# Assumed throughput: ~500 Mbit on the LAN, ~10 Mbit when the NAS is reached via tailscale/WAN
LAN_BPS=$((500 * 1000 * 1000 / 8))
WAN_BPS=$((10 * 1000 * 1000 / 8))

# No encryption wanted. restic always needs a repo password, so use an empty one;
# --insecure-no-password has to be passed to every restic command.
export RESTIC_REPOSITORY="$MNT/Framework"
# systemd runs this without $HOME, and restic needs it to locate its cache dir
export HOME="${HOME:-/root}"
restic() { command restic --insecure-no-password "$@"; }

mode="${1:-backup}"

# Unmount on exit (success or failure), but only if we were the ones who mounted it
mounted_by_us=0
cleanup() {
  if (( mounted_by_us )); then
    echo "Unmounting $MNT"
    cd / && umount "$MNT" || echo "!!!  Could not unmount $MNT  !!!"
  fi
}
trap cleanup EXIT

if ! mountpoint -q "$MNT"; then
  echo "Mounting NAS backup share"
  if ! mount -t nfs -o vers=4.2,rw,noatime,nconnect=4,timeo=100,retrans=3,soft "$NAS" "$MNT"; then
    echo "!!!  Could not mount the NAS share $NAS on $MNT (is the NAS reachable?)  !!!"
    exit 3
  fi
  mounted_by_us=1
fi
mkdir -p "$MNT/Framework"

ARGS=(
  --files-from "$HERE/include.txt"
  --exclude-file "$HERE/exclude.txt"
  --exclude-caches --one-file-system
  --tag laptop --host framework
)

if [[ "$mode" == "--estimate" ]]; then
  # No repo yet means nothing to compare against
  # The NAS can be slow to respond right after mounting (disks spinning up, soft NFS mount),
  # so give the repo a few tries before calling it unreachable.
  for try in 1 2 3; do
    err=$(restic cat config 2>&1 >/dev/null) && break
    (( try < 3 )) && sleep 15
  done
  if [[ -n "$err" ]] && ! restic cat config &>/dev/null; then
    echo "Cannot open repo $RESTIC_REPOSITORY after 3 tries: ${err//$'\n'/ }"
    echo "ESTIMATE_SECONDS=-1"; exit 0
  fi

  if ip route get "$NAS_HOST" | grep -q tailscale; then bps=$WAN_BPS; else bps=$LAN_BPS; fi

  start=$(date +%s)
  added=$(restic backup "${ARGS[@]}" --dry-run --json --quiet | jq -r 'select(.message_type=="summary") | .data_added')
  scan=$(( $(date +%s) - start ))
  echo "ESTIMATE_BYTES=$added"
  echo "ESTIMATE_SECONDS=$(( scan + added / bps ))"
  exit 0
fi

echo "Writing package manifests"
mkdir -p "$MANIFESTS" "$STAMP_DIR"
pacman -Qqen > "$MANIFESTS/pkglist.txt"
pacman -Qqem > "$MANIFESTS/aur.txt"
systemctl list-unit-files | awk '$2=="enabled"{print $1}' | { grep -v @ || true; } > "$MANIFESTS/services.txt"

if ! restic cat config &>/dev/null; then
  echo "Initializing new restic repo at $RESTIC_REPOSITORY"
  restic init
fi

# Refresh ~/.config/_packages (+ rc files, ~/bin) and commit the config repo locally (no push for now).
# Runs as the normal user. Never fails the backup: a problem just prints a warning.
USER_NAME=jake
CONF="/home/$USER_NAME/.config"
# Desktop notification from root (same trick as backup_nag.sh); never fails the backup
notify_user() {
  local uid; uid=$(id -u "$USER_NAME")
  runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
    notify-send -a backup "$@" 2>/dev/null || true
}

echo "Updating config repo"
if runuser -u "$USER_NAME" -- bash "$CONF/prep_repo.sh" >/dev/null; then
  n_pkg=$(wc -l < "$CONF/_packages/packages.txt"); n_aur=$(wc -l < "$CONF/_packages/packages_aur.txt")
  n_svc=$(wc -l < "$CONF/_packages/services.txt")
  runuser -u "$USER_NAME" -- bash -c '
    cd "$1" || exit 1
    git add -A
    if git diff --cached --quiet; then echo "Config repo: nothing new to commit"; else
      git commit -q -m "Backup $(date "+%Y-%m-%d %H:%M"): packages, services, dotfiles" \
        -m "Automatic snapshot from backup_restic.sh: $2 official + $3 AUR packages, $4 enabled services, shell rc files and ~/bin scripts."
    fi
  ' _ "$CONF" "$n_pkg" "$n_aur" "$n_svc" || {
    echo "!!!  Config repo commit failed (continuing)  !!!"
    notify_user -u normal -t 10000 "Config git commit failed" "The backup is continuing. Check ~/.config (git status)."
  }
else
  echo "!!!  prep_repo.sh failed (continuing)  !!!"
  notify_user -u normal -t 10000 "Config git update failed" "prep_repo.sh failed, so the package lists weren't refreshed. The backup is continuing."
fi

# Pull the latest PVE / Unraid backups into /root/backup. That dir is excluded from the restic
# run (exclude.txt) so they don't get copied back onto the array. Each pull is independent and
# never fails the backup: a box being offline just prints a warning and the previous copy stays.
PULL_DIR=/root/backup
pull_failed() {
  echo "!!!  Could not pull $1 (continuing; keeping previous copy)  !!!"
  notify_user -u normal -t 10000 "Backup pull failed: $1" "The laptop backup is continuing without a fresh copy."
}
echo "Pulling PVE and Unraid backups into $PULL_DIR"
mkdir -p "$PULL_DIR/proxmox-config" "$PULL_DIR/unraid-config" "$PULL_DIR/unraid-appdata"

# All three live on the NAS share we already have mounted ($MNT/Butlah/<name>), so this is a
# local rsync: restic repo pack files are immutable, so only new files are transferred.
# Live progress bar on a terminal; a stats summary (files, bytes, speed) either way.
RSYNC_INFO=stats2; [[ -t 1 ]] && RSYNC_INFO=progress2,stats2
for d in proxmox-config unraid-config unraid-appdata; do
  echo "--- $d"
  if [[ -d "$MNT/Butlah/$d" ]]; then
    rsync -a --delete --no-inc-recursive --info="$RSYNC_INFO" \
      "$MNT/Butlah/$d/" "$PULL_DIR/$d/" || pull_failed "$d"
  else
    # Not an error: the source backup may simply not exist yet (no notification)
    echo "Skipping $d: $MNT/Butlah/$d does not exist (yet)"
  fi
done

echo "Backing up"
start=$(date +%s)
# Run restic directly (no pipe) so it sees a terminal and draws its live progress line
# (elapsed, % done, files, bytes, ETA). When not on a terminal (timer runs), print a
# status line every 10s into the log instead of restic's default of one per minute.
[[ -t 1 ]] || export RESTIC_PROGRESS_FPS=0.1
restic backup "${ARGS[@]}"
elapsed=$(( $(date +%s) - start ))

date +%s > "$STAMP_DIR/last_success"

# One-line summary for the notifications, taken from the snapshot restic just made
restic snapshots latest --host framework --json | jq -r --arg t "$elapsed" '.[-1].summary |
  "\(.total_files_processed) files, \(.files_new) new, \(.files_changed) changed; added \((.data_added / 1048576 * 10 | round) / 10) MiB in \($t)s"' \
  > "$STAMP_DIR/last_summary"
cat "$STAMP_DIR/last_summary"

# Machine-readable stats for `backup_nag.sh --status`
restic snapshots latest --host framework --json | jq -r --arg t "$elapsed" '.[-1] as $s | $s.summary |
  "snapshot=\($s.short_id)\nelapsed=\($t)\nfiles=\(.total_files_processed)\nfiles_new=\(.files_new)\nfiles_changed=\(.files_changed)\nbytes_total=\(.total_bytes_processed)\nbytes_added=\(.data_added)\nbytes_added_packed=\(.data_added_packed // 0)"' \
  > "$STAMP_DIR/last_stats"
chmod 644 "$STAMP_DIR/last_success" "$STAMP_DIR/last_summary" "$STAMP_DIR/last_stats"

echo
echo "Pruning old snapshots"
restic forget "${KEEP[@]}" --prune --host framework

echo
echo "=== Repository stats ==="
restic snapshots --host framework --compact | tail -n 8
restic stats --mode raw-data
restic stats latest --mode restore-size

echo "!!!  Backup complete in ${elapsed}s  !!!"
