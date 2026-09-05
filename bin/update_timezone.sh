#!/bin/bash
#
# update_timezone.sh — set system timezone from IP geolocation, with fallbacks.
#
# Tries three independent geolocation services in order and validates the
# response before ever handing it to timedatectl, so a rate-limited or
# malformed reply can't wreck your system config.
#
# Usage:
#   ./update_timezone.sh          # detect and set the timezone
#   ./update_timezone.sh -n       # dry run: detect and print only, don't set
#   ./update_timezone.sh -v       # verbose: show which provider succeeded

set -u

DRY_RUN=0
VERBOSE=0
TIMEOUT=5   # seconds per provider

while getopts "nv" opt; do
    case "$opt" in
        n) DRY_RUN=1 ;;
        v) VERBOSE=1 ;;
        *) echo "Usage: $0 [-n] [-v]" >&2; exit 1 ;;
    esac
done

log() { [[ "$VERBOSE" -eq 1 ]] && echo "[update_timezone] $*" >&2; }

# A valid IANA timezone looks like Region/City (optionally Region/City/Subcity,
# or bare zones like UTC). Reject anything else, including JSON error bodies.
is_valid_tz() {
    [[ "$1" =~ ^[A-Za-z_]+(/[A-Za-z_+-]+){1,2}$ || "$1" == "UTC" ]]
}

# --- Provider 1: ipapi.co -----------------------------------------------
# Plain-text endpoint; returns just the zone name on success.
try_ipapi_co() {
    curl -fsS --max-time "$TIMEOUT" "https://ipapi.co/timezone" 2>/dev/null
}

# --- Provider 2: ip-api.com ----------------------------------------------
# JSON only, HTTP only (no HTTPS on the free tier). Extract the timezone
# field without depending on jq being installed.
try_ip_api_com() {
    local json
    json=$(curl -fsS --max-time "$TIMEOUT" "http://ip-api.com/json/?fields=status,timezone" 2>/dev/null) || return 1
    [[ "$json" == *'"status":"success"'* ]] || return 1
    echo "$json" | grep -oP '"timezone"\s*:\s*"\K[^"]+'
}

# --- Provider 3: geoip.ubuntu.com -----------------------------------------
# Canonical's own GeoIP lookup, used by Ubuntu's installer. XML response.
try_ubuntu_geoip() {
    curl -fsS --max-time "$TIMEOUT" "https://geoip.ubuntu.com/lookup" 2>/dev/null \
        | sed -n -e 's/.*<TimeZone>\(.*\)<\/TimeZone>.*/\1/p'
}

TZ_RESULT=""
for provider in "ipapi.co:try_ipapi_co" "ip-api.com:try_ip_api_com" "geoip.ubuntu.com:try_ubuntu_geoip"; do
    name="${provider%%:*}"
    fn="${provider##*:}"
    log "Trying $name..."
    result=$("$fn")
    if is_valid_tz "$result"; then
        TZ_RESULT="$result"
        log "Success via $name: $TZ_RESULT"
        break
    else
        log "$name failed or returned invalid data: ${result:-<empty>}"
    fi
done

if [[ -z "$TZ_RESULT" ]]; then
    echo "update_timezone: all geolocation providers failed; timezone left unchanged" >&2
    exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "$TZ_RESULT"
    exit 0
fi

if sudo timedatectl set-timezone "$TZ_RESULT"; then
    echo "Timezone set to $TZ_RESULT"
else
    echo "update_timezone: timedatectl rejected '$TZ_RESULT'" >&2
    exit 1
fi
