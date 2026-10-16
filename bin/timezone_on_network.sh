#!/bin/bash
#
# timezone_on_network.sh — run update_timezone.sh whenever a new network
# address appears (new connection, resume from suspend, etc).
# Waits for real internet access first, and debounces bursts of events.

DEBOUNCE=30   # seconds to ignore further events after a run

have_internet() {
    curl -fsS --max-time 3 -o /dev/null https://geoip.ubuntu.com/lookup 2>/dev/null
}

last_run=0
ip monitor address | while read -r line; do
    # Only react to new IPv4/IPv6 global addresses being added (not deletions)
    [[ "$line" == Deleted* || "$line" == *" lo "* || "$line" == *" scope host "* || "$line" == *" scope link "* ]] && continue
    now=$EPOCHSECONDS
    (( now - last_run < DEBOUNCE )) && continue
    last_run=$now

    # Wait up to ~60s for connectivity (DHCP/DNS may lag the address)
    for ((i = 0; i < 20; i++)); do
        have_internet && break
        sleep 3
    done
    have_internet || continue

    "$HOME/bin/update_timezone.sh"
    last_run=$EPOCHSECONDS
done
