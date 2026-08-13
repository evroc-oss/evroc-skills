#!/usr/bin/env bash
# evroc-networking public IP quota checker
# Returns the number of available public IPs vs the 3-IP quota.

set -euo pipefail

NEEDED="${1:-1}"

USED=$(evroc networking publicip list -o json 2>/dev/null | jq 'length')
AVAILABLE=$((3 - USED))

echo "Public IP quota: ${USED}/3 used, ${AVAILABLE} available"

if [[ ${AVAILABLE} -lt ${NEEDED} ]]; then
    echo "Error: Need ${NEEDED} public IPs, but only ${AVAILABLE} available."
    echo "Free IPs with: evroc networking publicip delete <id>"
    exit 1
fi
