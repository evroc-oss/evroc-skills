#!/usr/bin/env bash
# evroc-rancher public IP quota checker
# Returns the number of available public IPs vs the real org quota from the
# API (was hardcoded to 3 — orgs with raised limits reported wrong numbers).

set -euo pipefail

NEEDED="${1:-1}"

# Guard explicitly: under set -e an unguarded $(...) would abort the script
# silently (stderr swallowed), producing no diagnosis at all.
if ! DATA=$(evroc quotas orgquotas get -o json 2>/dev/null); then
    echo "Error: could not fetch organization quotas — the evroc CLI call failed." >&2
    echo "Check auth with 'evroc login', or run 'evroc quotas orgquotas get' to see the raw error." >&2
    exit 1
fi

USED=$(jq -r '(.status.quotaUsage.networking.publicIPs // 0)' <<<"${DATA}")
LIMIT=$(jq -r '(.spec.quotas.networking.publicIPs // 0)' <<<"${DATA}")
AVAILABLE=$(( LIMIT - USED ))

echo "Public IP quota: ${USED}/${LIMIT} used, ${AVAILABLE} available"

if [[ ${AVAILABLE} -lt ${NEEDED} ]]; then
    echo "Error: Need ${NEEDED} public IPs, but only ${AVAILABLE} available."
    echo "Free IPs with: evroc networking publicip delete <id>"
    echo "To request a quota increase, contact support@evroc.com"
    exit 1
fi
