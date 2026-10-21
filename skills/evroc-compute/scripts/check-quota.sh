#!/usr/bin/env bash
# evroc-compute QUOTA CHECKER
# Checks real organization quota usage from the API instead of hardcoded limits.
#
# Usage:
#   bash scripts/check-quota.sh              # show all org quotas (table)
#   bash scripts/check-quota.sh vcpus [N]    # show vCPUs usage vs limit; exit 1 if fewer than N available
#
# Resource keys: vcpus | memory | blockstorage | gpus | all
# Requires: evroc CLI authenticated, jq
#
# NOTE: org quotas span ALL projects in the organization. Usage in a different
# project consumes the same org-level limit.

set -euo pipefail

command -v jq >/dev/null || { echo "Error: jq is required" >&2; exit 1; }

RESOURCE="${1:-}"
NEEDED="${2:-}"

# One JSON fetch for all parsing below. Guard explicitly: under set -e an
# unguarded $(...) would abort the script silently (stderr swallowed), and a
# diagnostic that dies without a message is worse than the error it checks.
if ! DATA=$(evroc quotas orgquotas get -o json 2>/dev/null); then
    echo "Error: could not fetch organization quotas — the evroc CLI call failed." >&2
    echo "Check auth with 'evroc login', or run 'evroc quotas orgquotas get' to see the raw error." >&2
    exit 1
fi

# Show the human-readable table (single CLI call, goes to stdout)
evroc quotas orgquotas get 2>/dev/null || true

num() { # num <group> <field>
    jq -r --arg g "$1" --arg f "$2" \
        '((.status.quotaUsage[$g][$f] // 0) | if type == "number" then . else 0 end)' <<<"${DATA}"
}
limit() { # limit <group> <field>
    jq -r --arg g "$1" --arg f "$2" \
        '((.spec.quotas[$g][$f] // 0) | if type == "number" then . else 0 end)' <<<"${DATA}"
}

check_numeric() { # check_numeric <label> <group> <field> [needed]
    local label="$1" group="$2" field="$3" needed="${4:-}"
    local used avail
    used=$(num "${group}" "${field}")
    avail=$(( $(limit "${group}" "${field}") - used ))
    echo "${label}: ${used} used, ${avail} available"
    if [[ -n "${needed}" ]] && (( avail < needed )); then
        echo "Error: need ${needed} ${label}, but only ${avail} available." >&2
        echo "To request a quota increase, contact support@evroc.com" >&2
        exit 1
    fi
}

check_gpus() { # check_gpus [needed]
    local needed="${1:-}"
    local model used lim avail any_ok=0
    echo "GPUs:"
    # union of models in quota spec and usage; one row each (limit, usage)
    while IFS=$'\t' read -r model lim used; do
        avail=$(( lim - used ))
        echo "  ${model}: ${used} used, ${avail} available"
        if [[ -n "${needed}" ]] && (( avail >= needed )); then
            any_ok=1
        fi
    done < <(jq -r '
        ( (.spec.quotas.compute.gpus // {}) + (.status.quotaUsage.compute.gpus // {}) ) as $models
        | . as $root
        | $models | keys[] as $m
        | [ $m,
            ($root.spec.quotas.compute.gpus[$m] // 0),
            ($root.status.quotaUsage.compute.gpus[$m] // 0) ]
        | @tsv' <<<"${DATA}")
    if [[ -n "${needed}" ]] && (( any_ok == 0 )); then
        echo "Error: need ${needed} GPUs, but every model with quota is exhausted." >&2
        echo "To request a quota increase, contact support@evroc.com" >&2
        exit 1
    fi
}

case "${RESOURCE}" in
    "")
        exit 0
        ;;
    vcpus)
        check_numeric "vCPUs" compute vCPUs "${NEEDED}"
        ;;
    memory)
        jq -r '"Memory: \(.status.quotaUsage.compute.memory // "0") used, limit \(.spec.quotas.compute.memory // "unknown")"' <<<"${DATA}"
        ;;
    blockstorage)
        jq -r '"Block Storage: \(.status.quotaUsage.compute.blockStorage // "0") used, limit \(.spec.quotas.compute.blockStorage // "unknown")"' <<<"${DATA}"
        ;;
    gpus)
        check_gpus "${NEEDED}"
        ;;
    all)
        check_numeric "vCPUs" compute vCPUs
        check_gpus
        jq -r '"Memory: \(.status.quotaUsage.compute.memory // "0") used, limit \(.spec.quotas.compute.memory // "unknown")"' <<<"${DATA}"
        jq -r '"Block Storage: \(.status.quotaUsage.compute.blockStorage // "0") used, limit \(.spec.quotas.compute.blockStorage // "unknown")"' <<<"${DATA}"
        ;;
    *)
        echo "Error: unknown resource '${RESOURCE}'. Use: vcpus | memory | blockstorage | gpus | all" >&2
        exit 1
        ;;
esac
