#!/usr/bin/env bash
# evroc-rancher public IP quota checker
# Returns the number of available public IPs vs the 3-IP quota.

set -euo pipefail

USED=$(evroc networking publicip list -o json 2>/dev/null | jq '.items | length')
AVAILABLE=$((3 - USED))

echo "Public IP quota: ${USED}/3 used, ${AVAILABLE} available"

if [[ ${AVAILABLE} -lt $1 ]]; then
    echo "Error: Need ${1} public IPs, but only ${AVAILABLE} available."
    echo "Free IPs with: evroc networking publicip delete <id>"
    exit 1
fi
