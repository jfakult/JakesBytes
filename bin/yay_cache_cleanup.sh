#!/usr/bin/env bash
# Prune ~/.cache/yay: keep the newest N built packages per AUR package, and
# delete stale downloaded sources (files carrying an old version string).
# Usage: yay_cache_cleanup.sh [-n] [-k N]   (-n = dry run, -k = versions to keep, default 3)
set -u

keep=3
dry=0
while getopts "nk:" opt; do
  case $opt in
    n) dry=1 ;;
    k) keep=$OPTARG ;;
    *) echo "usage: $0 [-n] [-k N]" >&2; exit 1 ;;
  esac
done

cache="${XDG_CACHE_HOME:-$HOME/.cache}/yay"
[ -d "$cache" ] || { echo "no yay cache at $cache" >&2; exit 1; }

before=$(du -sk "$cache" 2>/dev/null | cut -f1)

for dir in "$cache"/*/; do
  dir=${dir%/}
  [ -d "$dir/pkg" ] && chmod u+rwx "$dir/pkg" 2>/dev/null

  # 1. built packages: keep the newest $keep
  if [ $dry -eq 1 ]; then
    paccache -d -k"$keep" -c "$dir" 2>/dev/null | grep -v 'no candidate'
  else
    paccache -r -k"$keep" -c "$dir" 2>/dev/null | grep -v 'no candidate'
  fi

  # 2. stale source downloads: top-level files with a version string that
  #    doesn't match the current pkgver
  [ -f "$dir/PKGBUILD" ] || continue
  pkgver=$(sed -n 's/^pkgver=//p' "$dir/PKGBUILD" | head -1 | tr -d "\"'")
  [ -n "$pkgver" ] || continue
  while IFS= read -r -d '' f; do
    base=${f##*/}
    case $base in
      PKGBUILD|.SRCINFO|*.install|*.sh|*.patch|*.diff|*.pkg.tar.*|*.sig) continue ;;
    esac
    [[ $base == *"$pkgver"* ]] && continue
    [[ $base =~ [0-9]+\.[0-9]+ ]] || continue
    if [ $dry -eq 1 ]; then echo "would remove $f"; else rm -v -- "$f"; fi
  done < <(find "$dir" -maxdepth 1 -type f -print0)
done

after=$(du -sk "$cache" 2>/dev/null | cut -f1)
echo "yay cache: $((before/1024)) MB -> $((after/1024)) MB"
