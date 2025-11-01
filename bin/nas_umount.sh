#!/usr/bin/env bash
set -euo pipefail

MNT="${1:-}"   # Local mount point

if [[ -z "$MNT" ]]; then
  echo "Usage: $0 <local-mount-folder>"
  echo
  echo "Example: $0 /mnt/NAS/Share"
  echo
  echo "Currently mounted NFS points:"
  df -h -t nfs4
  exit 1
fi

if ! mountpoint -q "$MNT"; then
  echo "$MNT is not a mountpoint."
  exit 0
fi

echo "Unmounting $MNT ..."
sudo umount "$MNT"
echo "Unmounted OK."
