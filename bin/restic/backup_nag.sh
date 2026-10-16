#!/usr/bin/env bash
# Backup scheduler/reminder. Meant to run as ROOT from a system timer (every ~30 min).
#
#   age < 1 day                       -> nothing
#   estimate < 3 min                  -> run the backup automatically, mako notification before/after
#   age >= 3 days (and not snoozed)   -> mako heads-up + wofi menu: Run now / Ask me tomorrow / Ask me next week
#   menu closed without choosing      -> ask again in an hour
#
# mako can't render clickable buttons, so the choice is a wofi dmenu popup.
#
# Usage: backup_nag.sh [--test [ESTIMATE_SECONDS] | --status]
#   --test  show the real dialog, ignore age/snooze, separate state dir, never runs a backup.
#           "Run now" just pops a second mako notification. Can be run as your normal user.
#           ESTIMATE_SECONDS fakes the estimate (default 600; <180 shows the auto-run path instead).
set -u

usage() {
  cat <<'USAGE'
backup_nag.sh - decides when to back up the laptop, and nags if it's overdue

Usage: backup_nag.sh [--test [ESTIMATE_SECONDS] | --status | --watch | -h | --help]

Meant to run as root from a system timer (about every 30 min):
  last backup < 1 day old          do nothing
  estimate < 3 min                 run backup_restic.sh automatically + mako notifications
  last backup >= 3 days old        mako heads-up and a wofi menu:
                                     Run now / Ask me tomorrow / Ask me next week
  menu closed without choosing     ask again in an hour

Options:
  --test [SECONDS]  Show the real dialog with a fake estimate (default 600; use
                    60 to see the auto-run path). Ignores age and snooze, uses a
                    separate state dir, and never runs a backup. "Run now" only
                    pops a second notification. Runs fine as a normal user.
  -s, --status      Show stats for the last backup (when, how long ago, duration, data
                    sent, rate, files), plus snooze / cached estimate / timer state.
                    Doesn't need root.
  -w, --watch, -f   Follow the journal for backup_nag.service (last 50 lines, then live).
                    Backup output is logged there too. Ctrl-C to stop.
  -h, --help        Show this help.

State: /var/lib/restic-backup/nag/ (snooze time, cached estimate, logs)
Colors: taken from ~/.config/system_styles.sh
USAGE
}
dur() { local s=$1; if (( s >= 86400 )); then printf '%dd %dh' $((s/86400)) $((s%86400/3600))
        elif (( s >= 3600 )); then printf '%dh %dm' $((s/3600)) $((s%3600/60))
        elif (( s >= 60 )); then printf '%dm %ds' $((s/60)) $((s%60)); else printf '%ds' "$s"; fi; }
say() { echo "[$(date +%H:%M:%S)] $*"; }   # goes to the journal / terminal
status() {
  local D=/var/lib/restic-backup now last; now=$(date +%s)
  last=$(cat "$D/last_success" 2>/dev/null || echo 0)
  hum() { numfmt --to=iec-i --suffix=B --format=%.1f "${1:-0}"; }
  if (( last == 0 )); then echo "Last backup:   never"; else
    echo "Last backup:   $(date -d "@$last" '+%a %Y-%m-%d %H:%M:%S')  ($(dur $((now - last))) ago)"
  fi
  if [[ -r $D/last_stats ]]; then
    local snapshot elapsed files files_new files_changed bytes_total bytes_added bytes_added_packed
    # shellcheck disable=SC1091
    source "$D/last_stats"
    echo "Snapshot:      $snapshot"
    echo "Duration:      $(dur "$elapsed")"
    echo "Data sent:     $(hum "$bytes_added") ($(hum "$bytes_added_packed") after compression)"
    if (( elapsed > 0 )); then
      echo "Data rate:     $(hum $(( bytes_added / elapsed )))/s sent, $(hum $(( bytes_total / elapsed )))/s scanned"
    fi
    echo "Source size:   $(hum "$bytes_total") in $files files ($files_new new, $files_changed changed)"
  else
    echo "Summary:       $(cat "$D/last_summary" 2>/dev/null || echo unknown)"
    echo "(no detailed stats yet; they are recorded from the next backup on)"
  fi
  local next est tick t kind
  next=$(cat "$D/nag/next" 2>/dev/null || echo 0)
  est=$(cat "$D/nag/est" 2>/dev/null || echo -1)
  # (the timer is relative to the last run, so read the next time from list-timers)
  tick=$(systemctl list-timers backup_nag.timer --output=json 2>/dev/null | jq -r '.[0].next // empty')
  tick=$(( ${tick:-0} / 1000000 )); (( tick > 0 )) || tick=$now
  (( est >= 0 )) && echo "Next estimate: ~$(dur "$est")"
  if (( next > now )); then echo "Nag snoozed:   until $(date -d "@$next" '+%a %Y-%m-%d %H:%M') (in $(dur $((next - now))))"; fi
  # Earliest time the timer could start a backup. From 1 day on it runs automatically if
  # the estimate is short (the estimate is only computed then, so it may be unknown now);
  # otherwise it prompts once the backup is 3 days old (unless snoozed).
  local nag_t=$(( last + 3 * 86400 )); (( next > nag_t )) && nag_t=$next
  if (( est >= 180 )); then t=$nag_t; kind="prompts you first"
  elif (( est >= 0 )); then t=$(( last + 86400 )); kind="automatic"
  elif [[ -f $D/nag/est ]]; then t=$nag_t
    kind="estimate failed at $(date -d "@$(stat -c %Y "$D/nag/est")" +%H:%M), so no auto-run; prompts you"
  else t=$(( last + 86400 ))
    kind="automatic if estimate < 3 min, else prompts from $(date -d "@$nag_t" '+%a %H:%M')"; fi
  (( tick > t )) && t=$tick
  echo "Next backup:   $(date -d "@$t" '+%a %Y-%m-%d %H:%M:%S') ($( (( t > now )) && echo "in $(dur $((t - now)))" || echo "due now")) - $kind"
  echo "Next check:    $(date -d "@$tick" '+%a %H:%M:%S') (timer runs about every 30 min)"
}
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -s|--status) status; exit 0 ;;
  -w|--watch|-f) exec journalctl -u backup_nag.service -n 50 -f ;;
  ""|--test) ;; *) usage >&2; exit 2 ;; esac

USER_NAME=jake
USER_UID=$(id -u "$USER_NAME")
HERE="$(dirname "$(readlink -f "$0")")"
BACKUP="$HERE/backup_restic.sh"
STAMP=/var/lib/restic-backup/last_success
SUMMARY=/var/lib/restic-backup/last_summary
STATE=/var/lib/restic-backup/nag

MIN_AUTO_AGE=$((1 * 86400))   # never auto-run more often than this
NAG_AGE=$((3 * 86400))        # start nagging after this
AUTO_RUN_SECONDS=180          # auto-run if estimated faster than this
EST_CACHE_SECONDS=$((6 * 3600))

TEST=0; FAKE_EST=600
if [[ "${1:-}" == "--test" ]]; then
  TEST=1; [[ -n "${2:-}" ]] && FAKE_EST="$2"
  STATE="$HOME/.local/state/backup_nag_test"
  echo "[test] state dir $STATE, fake estimate ${FAKE_EST}s"
fi
mkdir -p "$STATE"

# Run a command inside jake's graphical session (we're root under the timer)
as_user() {
  if (( EUID == 0 )); then
    runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_UID" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_UID/bus" \
      WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" "$@"
  else
    "$@"
  fi
}
notify() { as_user notify-send -a backup "$@"; }

exec 9>"$STATE/lock"; flock -n 9 || { say "another backup_nag/backup run is in progress; nothing to do"; exit 0; }   # one at a time

now=$(date +%s)
last=$(cat "$STAMP" 2>/dev/null || echo 0)
age_s=$(( now - last ))
if (( last == 0 )); then age="never"; else age="$(( age_s / 86400 )) days ago"; fi

# A backup finished after we last snoozed: forget the snooze
if [[ -f "$STATE/next" && $last -gt $(stat -c %Y "$STATE/next") ]]; then rm -f "$STATE/next"; fi

if (( TEST == 0 )); then
  if (( age_s < MIN_AUTO_AGE )); then
    say "last backup $(dur "$age_s") ago (under 1 day): nothing to do"; exit 0
  fi
  say "last backup ${age_s}s ago ($(dur "$age_s")): backup is due"
fi

# ---- estimate (cached, since a dry run scans everything) ----
est=-1
if (( TEST )); then
  est=$FAKE_EST
else
  if [[ -f "$STATE/est" && $(( now - $(stat -c %Y "$STATE/est") )) -lt $EST_CACHE_SECONDS && $(cat "$STATE/est") -ge 0 ]]; then
    est=$(cat "$STATE/est")
  elif "$BACKUP" --estimate >"$STATE/est.out" 2>&1; then
    est=$(sed -n 's/^ESTIMATE_SECONDS=//p' "$STATE/est.out"); est=${est:--1}
    # Only cache a real estimate: a failure (NAS asleep, etc.) is retried on the next run
    if (( est >= 0 )); then echo "$est" > "$STATE/est"; rm -f "$STATE/est.err"
    else say "estimate unavailable: $(grep -v '^ESTIMATE_' "$STATE/est.out" | tail -n1)"; fi
  else
    say "estimate run FAILED (exit $?): $(tail -n1 "$STATE/est.out")"
  fi
  (( est >= 0 )) && say "estimated backup time: ${est}s"
fi

# ---- quick enough: just do it ----
if (( est >= 0 && est < AUTO_RUN_SECONDS )); then
  say "estimate ${est}s is under ${AUTO_RUN_SECONDS}s: running the backup automatically"
  notify -u low -t 5000 "Backup starting" "Estimated ${est}s (last backup: $age)"
  if (( TEST )); then
    sleep 2; notify -u low -t 8000 "Backup finished (test)" "Simulated, nothing was run"; exit 0
  fi
  if "$BACKUP" 2>&1 | tee "$STATE/auto.log"; [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    rm -f "$STATE/est" "$STATE/next"
    summary=$(cat "$SUMMARY" 2>/dev/null)
    say "automatic backup finished: ${summary:-done}"
    notify -u low -t 10000 "Backup finished" "${summary:-Done}"
  else
    say "automatic backup FAILED (see $STATE/auto.log)"
    notify -u critical "Backup FAILED" "See $STATE/auto.log"
  fi
  exit 0
fi

# ---- too slow to auto-run: nag if old enough and not snoozed ----
if (( TEST == 0 )); then
  why="not auto-running ($( ((est >= 0)) && echo "estimate ${est}s is not under ${AUTO_RUN_SECONDS}s" || echo "no usable estimate"))"
  if (( age_s < NAG_AGE )); then
    say "$why; last backup $(dur "$age_s") ago, nagging starts at $(dur "$NAG_AGE") (in $(dur $((NAG_AGE - age_s))))"; exit 0
  fi
  if [[ -f "$STATE/next" && $now -lt $(cat "$STATE/next") ]]; then
    say "$why; nag snoozed until $(date -d "@$(cat "$STATE/next")" '+%a %H:%M') (in $(dur $(( $(cat "$STATE/next") - now ))))"; exit 0
  fi
  say "$why; last backup $(dur "$age_s") ago: nagging"
fi

snooze() { echo $(( now + $1 )) > "$STATE/next"; }
est_txt="estimate unknown"; (( est >= 0 )) && est_txt="estimate ~$(( (est + 59) / 60 )) min"
# Menu colors from the shared palette (strip the alpha byte: GTK css wants #rrggbb)
# shellcheck disable=SC1091
source "/home/$USER_NAME/.config/system_styles.sh"
c() { echo "${1:0:7}"; }
STYLE="$STATE/wofi.css"
sed -e "s/@BG@/$(c "$COLOR_DARK_BACKGROUND")/g" -e "s/@BG_ALT@/$(c "$COLOR_DARK_BACKGROUND_ALT")/g" \
    -e "s/@TEXT@/$(c "$COLOR_DARK_TEXT")/g" -e "s/@TEXT_ALT@/$(c "$COLOR_DARK_TEXT_ALT")/g" \
    -e "s/@HIGHLIGHT@/$(c "$COLOR_DARK_HIGHLIGHT")/g" -e "s/@FONT@/$FONT/g" -e "s/@FONT_SIZE@/$FONT_SIZE/g" \
    "$HERE/wofi.css" > "$STYLE"
chmod 644 "$STYLE"

notify -u normal -t 5000 "Backup overdue" "Last backup: $age ($est_txt)"

choice=$(printf '%s\n' "Run now ($est_txt)" "Ask me tomorrow" "Ask me next week" \
  | as_user wofi --dmenu --gtk-dark --style "$STYLE" --location top_right --xoffset -40 --yoffset 150 --width 440 --height 170 \
      --prompt "Backup overdue: last $age" --hide-search --cache-file /dev/null 2>/dev/null)

case "$choice" in
  "Run now"*)
    if (( TEST )); then
      notify -u normal -t 8000 "Backup started (test)" "This is where the real backup would run"
    else
      rm -f "$STATE/next"
      notify -u low -t 5000 "Backup starting" "Estimated ${est_txt#estimate }"
      if "$BACKUP" 2>&1 | tee "$STATE/manual.log"; [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        rm -f "$STATE/est"
        summary=$(cat "$SUMMARY" 2>/dev/null)
        notify -u low -t 10000 "Backup finished" "${summary:-Done}"
      else
        notify -u critical "Backup FAILED" "See $STATE/manual.log"
      fi
    fi ;;
  "Ask me tomorrow")  snooze 86400 ;;
  "Ask me next week") snooze 604800 ;;
  *)                  snooze 3600 ;;
esac
say "menu choice: '${choice:-<closed, asking again in 1h>}'"
(( TEST )) && echo "[test] choice='${choice}'"
exit 0
