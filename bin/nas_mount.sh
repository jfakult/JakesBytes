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

# NFS support missing from the running kernel (e.g. kernel updated without reboot)
if ! grep -qw nfs4 /proc/filesystems && ! sudo modprobe nfs 2>/dev/null; then
  echo "Error: this kernel ($(uname -r)) has no NFS support and the module can't be loaded."
  if [[ ! -d "/usr/lib/modules/$(uname -r)" ]]; then
    echo "Modules for the running kernel are gone (likely updated without reboot). Reboot to fix."
  else
    echo "Check that the nfs module/nfs-utils is installed."
  fi
  exit 1
fi

echo "Mounting ${SERVER}:${EXPORT} -> ${MNT} (NFS v4.2)"
sudo mount -t nfs -o vers=4.2,rw,noatime,nconnect=4,timeo=100,retrans=3,soft "${SERVER}:${EXPORT}" "$MNT" -v

echo "Mounted OK."
