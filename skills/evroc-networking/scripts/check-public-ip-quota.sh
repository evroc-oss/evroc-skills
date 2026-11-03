#!/usr/bin/env bash
# evroc-networking ELASTIC IPv4 QUOTA CHECKER
# Checks real org quota from the API instead of a hardcoded 3-address limit.
#
# Usage:
#   bash scripts/check-public-ip-quota.sh <needed>
#
# Does NOT check IPv6 — IPv6 addresses are abundant and auto-assigned from subnet
# prefixes without per-address quotas.
#
# NOTE: org quotas span ALL projects in the organization. Usage in a different
# project consumes the same org-level limit.

set -euo pipefail

NEEDED="${1:-1}"

command -v jq >/dev/null || { echo "Error: jq is required" >&2; exit 1; }

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

echo "Elastic IPv4 quota: ${USED}/${LIMIT} used, ${AVAILABLE} available"

if [[ ${AVAILABLE} -lt ${NEEDED} ]]; then
    echo "Error: Need ${NEEDED} elastic IPv4 addresses, but only ${AVAILABLE} available."
    echo "Free IPs with: evroc networking publicip delete <id>"
    echo "Note: IPv6 addresses have no quota. Each VM in an IPv6-enabled subnet gets one automatically."
    echo "To request a quota increase, contact support@evroc.com"
    exit 1
fi
