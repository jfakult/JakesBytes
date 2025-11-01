#!/bin/sh
# Usage: network_speed.sh <window_seconds>
# Prints: "<ul_mbps> <dl_mbps>"

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: $0 <window_seconds>"
  echo "Measures upload and download speeds in Mbps over the given window length."
  exit 0
fi

WINDOW="$1"
if ! printf '%s' "$WINDOW" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then
  echo "Error: must supply a positive window length in seconds" >&2
  exit 1
fi

# Find primary interface (first UP non-lo with default route)
IFACE=$(ip route get 8.8.8.8 2>/dev/null \
  | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')

#echo $IFACE
[ -z "$IFACE" ] && IFACE=$(ip link | awk -F: '$1 ~ /^[0-9]+$/ && $2 !~ / lo/ {gsub(" ", "", $2); print $2; exit}')
#echo $IFACE

IFACE="wlan0"

RX1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

sleep "$WINDOW"

RX2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

#echo RX1=$RX1 RX2=$RX2 TX1=$TX1 TX2=$TX2

# Bytes → bits → Mbps
DL=$(echo "scale=2; ($RX2 - $RX1) * 8 / $WINDOW / 1000000" | bc)
UL=$(echo "scale=2; ($TX2 - $TX1) * 8 / $WINDOW / 1000000" | bc)

echo "DL|float|${DL}"
echo "UL|float|${UL}"
echo ""