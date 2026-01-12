#!/bin/bash
set -euo pipefail

# Battery notification script
# Sends desktop notifications when battery is low and discharging.
# Designed to be run periodically (e.g., via systemd timer).

# --- Config ---
SYNC_KEY="battery-low"   # notification "replacement" key
ICON="battery"           # change if you want (or use a path)
# Optional color hints (work with some daemons like dunst). Customize or delete.
HINTS_30=(--hint=string:bgcolor:#222222 --hint=string:fgcolor:#ffffff)
HINTS_20=(--hint=string:bgcolor:#442200 --hint=string:fgcolor:#ffffff)
HINTS_10=(--hint=string:bgcolor:#660000 --hint=string:fgcolor:#ffffff)

INTERVAL_LT30=600   # battery below 30% == notify every 10 min
INTERVAL_LT20=300   # 5 min
# Note: Below 10%, it will notify every time percentage decrements (on 1 minute interval still)

# State file (persistent across timer runs)
STATE_DIR="/tmp/battery-notify"
STATE_FILE="$STATE_DIR/state.env"

mkdir -p "$STATE_DIR"

# --- Read battery from sysfs ---
BAT_PATH=""
for d in /sys/class/power_supply/BAT*; do
  if [[ -d "$d" ]]; then
    BAT_PATH="$d"
    break
  fi
done

if [[ -z "$BAT_PATH" ]]; then
  # No battery found (desktop?), just exit quietly.
  exit 0
fi

cap="$(<"$BAT_PATH/capacity")"
status="$(<"$BAT_PATH/status")"

# Normalize a bit
status_lc="$(tr '[:upper:]' '[:lower:]' <<<"$status")"

# If charging/full, clear state and exit
if [[ "$status_lc" == "charging1" || "$status_lc" == "full1" ]]; then
  rm -f "$STATE_FILE"
  exit 0
fi

# --- Load previous state (if any) ---
last_pct=""
ts30=0
ts20=0

if [[ -f "$STATE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$STATE_FILE" || true
fi

now="$(date +%s)"

notify() {
  local urgency="$1"
  local title="$2"
  local body="$3"
  shift 3
  notify-send \
    -h "string:x-canonical-private-synchronous:$SYNC_KEY" \
    -u "$urgency" \
    -i "$ICON" \
    -c bottom-right \
    "$@" \
    "$title" "$body"
}

should_notify=false
urgency="low"
extra_hints=()

title="Battery Low"
body="Battery: ${cap}% (Discharging)"

# Decide notification behavior (priority: <10, then <20, then <30)
if (( cap < 10 )); then
  urgency="critical"
  extra_hints=("${HINTS_10[@]}")
  # Notify every time percentage decrements
  if [[ -z "${last_pct:-}" ]]; then
    should_notify=true
  else
    # Only notify if it went down since last run
    if (( cap < last_pct )); then
      should_notify=true
    fi
  fi
elif (( cap < 20 )); then
  urgency="critical"
  extra_hints=("${HINTS_20[@]}")
  # Notify immediately when crossing into <20, otherwise every 5 min
  if [[ -z "${last_pct:-}" ]] || (( last_pct >= 20 )); then
    should_notify=true
    ts20="$now"
  else
    if (( now - ts20 >= INTERVAL_LT20 )); then
      should_notify=true
      ts20="$now"
    fi
  fi
elif (( cap < 30 )); then
  urgency="low"
  extra_hints=("${HINTS_30[@]}")
  # Notify immediately when crossing into <30, otherwise every 15 min
  if [[ -z "${last_pct:-}" ]] || (( last_pct >= 30 )); then
    should_notify=true
    ts30="$now"
  else
    if (( now - ts30 >= INTERVAL_LT30 )); then
      should_notify=true
      ts30="$now"
    fi
  fi
else
  # >=30% and discharging: clear timers so next crossing notifies immediately
  ts30=0
  ts20=0
fi

if [[ "$should_notify" == true ]]; then
  notify "$urgency" "$title" "$body" "${extra_hints[@]}"
fi

# --- Save state (atomic write) ---
tmp="$(mktemp)"
{
  echo "last_pct=$cap"
  echo "ts30=${ts30:-0}"
  echo "ts20=${ts20:-0}"
} > "$tmp"
mv "$tmp" "$STATE_FILE"
