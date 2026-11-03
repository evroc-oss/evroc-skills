#!/usr/bin/env bash
# evroc-loadbalancer QUOTA CHECKER
# Checks real organization quota usage from the API instead of hardcoded limits.
#
# Usage:
#   bash scripts/check-quota.sh              # show all org quotas (table)
#   bash scripts/check-quota.sh lbs [N]     # load balancer count; exit 1 if fewer than N available
#
# NOTE: org quotas span ALL projects in the organization. Usage in a different
# project consumes the same org-level limit.

set -euo pipefail

command -v jq >/dev/null || { echo "Error: jq is required" >&2; exit 1; }

RESOURCE="${1:-}"
NEEDED="${2:-}"

# Guard explicitly: under set -e an unguarded $(...) would abort the script
# silently (stderr swallowed), producing no diagnosis at all.
if ! DATA=$(evroc quotas orgquotas get -o json 2>/dev/null); then
    echo "Error: could not fetch organization quotas — the evroc CLI call failed." >&2
    echo "Check auth with 'evroc login', or run 'evroc quotas orgquotas get' to see the raw error." >&2
    exit 1
fi

# Show the human-readable table (single CLI call, goes to stdout)
evroc quotas orgquotas get 2>/dev/null || true

case "${RESOURCE}" in
    "")
        exit 0
        ;;
    lbs|"loadbalancers")
        USED=$(jq -r '(.status.quotaUsage.loadBalancer.loadBalancers // 0)' <<<"${DATA}")
        LIMIT=$(jq -r '(.spec.quotas.loadBalancer.loadBalancers // 0)' <<<"${DATA}")
        AVAIL=$(( LIMIT - USED ))
        echo "Load Balancers: ${USED} used, ${AVAIL} available"
        if [[ -n "${NEEDED}" ]] && (( AVAIL < NEEDED )); then
            echo "Error: need ${NEEDED} load balancers, but only ${AVAIL} available." >&2
            echo "To request a quota increase, contact support@evroc.com" >&2
            exit 1
        fi
        ;;
    *)
        echo "Error: unknown resource '${RESOURCE}'. Use: lbs" >&2
        exit 1
        ;;
esac
