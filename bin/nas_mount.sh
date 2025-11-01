#!/usr/bin/env bash
set -euo pipefail

MNT="${1:-}"                      # Local mount point
EXPORT="${2:-/mnt/user/Share}"    # NFS export path
SERVER="${3:-192.168.1.199}"      # NFS server address

if [[ -z "$MNT" ]]; then
  echo "Usage: $0 <local-mount-folder> <export> <server>"
  echo
  echo "Example: $0 /mnt/NAS/Share /mnt/user/Share 192.168.1.199"
  echo
  echo "Existing mounts:"
  #findmnt | grep NAS | awk '{print $1"\t"$2"\t"$3}'
  df -h -t nfs4
  exit 1
fi

# If mount folder doesn't exist, quit (root has to create it)
if [[ ! -d "$MNT" ]]; then
  echo "Mount point $MNT does not exist. Please create it as root."
  exit 1
fi

# If already mounted, skip
if mountpoint -q "$MNT"; then
  echo "Already mounted at $MNT"
  exit 0
fi

echo "Mounting ${SERVER}:${EXPORT} -> ${MNT} (NFS v4.2)"
sudo mount -t nfs -o vers=4.2,rw,noatime "${SERVER}:${EXPORT}" "$MNT"
echo "Mounted OK."
