#!/usr/bin/env bash
# evroc-networking ELASTIC IPv4 QUOTA CHECKER
# Returns the number of available ELASTIC IPv4 addresses vs the 3-address quota.
# Does NOT check IPv6 — IPv6 addresses are abundant and auto-assigned from subnet
# prefixes without per-address quotas.
#
# Requires: evroc CLI authenticated, jq

set -euo pipefail

NEEDED="${1:-1}"

USED=$(evroc networking publicip list -o json 2>/dev/null | jq 'length')
AVAILABLE=$((3 - USED))

echo "Elastic IPv4 quota: ${USED}/3 used, ${AVAILABLE} available"

if [[ ${AVAILABLE} -lt ${NEEDED} ]]; then
    echo "Error: Need ${NEEDED} elastic IPv4 addresses, but only ${AVAILABLE} available."
    echo "Free IPv4s with: evroc networking publicip delete <id>"
    echo "Note: IPv6 addresses have no quota. Each VM in an IPv6-enabled subnet gets one automatically."
    exit 1
fi
