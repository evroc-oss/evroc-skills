#!/usr/bin/env bash
# evroc-think GPU QUOTA CHECKER
# Checks real organization GPU quota usage from the API for Think Models
# dedicated instances (org quota covers GPU-backed dedicated instances).
#
# Usage:
#   bash scripts/check-quota.sh              # show all org quotas (table)
#   bash scripts/check-quota.sh gpus [N]     # exit 1 if no GPU model has N available
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

any_ok=0
case "${RESOURCE}" in
    "")
        exit 0
        ;;
    gpus)
        echo "GPUs:"
        # union of models in quota spec and usage; one row each (limit, usage)
        while IFS=$'\t' read -r model lim used; do
            avail=$(( lim - used ))
            echo "  ${model}: ${used} used, ${avail} available"
            if [[ -n "${NEEDED}" ]] && (( avail >= NEEDED )); then
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
        if [[ -n "${NEEDED}" ]] && (( any_ok == 0 )); then
            echo "Error: need ${NEEDED} GPUs, but every model with quota is exhausted." >&2
            echo "To request a quota increase, contact support@evroc.com" >&2
            exit 1
        fi
        ;;
    *)
        echo "Error: unknown resource '${RESOURCE}'. Use: gpus" >&2
        exit 1
        ;;
esac
