#!/usr/bin/env bash
# evroc-storage PROJECT QUOTA CHECKER (Object Storage)
# Object storage quota is project-scoped, not org-scoped: it comes from
# `evroc quotas projectquotas get` (a hidden but functional CLI command),
# not from `evroc quotas orgquotas get`.
#
# Usage:
#   bash scripts/check-quota.sh              # show project object storage quota (table)
#   bash scripts/check-quota.sh size [N_GB]  # exit 1 if fewer than N_GB available
#
# NOTE: usage is per project. Available = limit - current usage in this project.

set -euo pipefail

command -v jq >/dev/null || { echo "Error: jq is required" >&2; exit 1; }

RESOURCE="${1:-}"
NEEDED="${2:-}"

DATA=$(evroc quotas projectquotas get -o json 2>/dev/null)

# Show the human-readable table (single CLI call, goes to stdout)
evroc quotas projectquotas get 2>/dev/null

# Normalize a size string like "10TB", "512GB", "100MB" to MB (integer).
to_mb() { # to_mb <string>
    local s="${1:-0}"
    # extract number (may be decimal) and unit
    if [[ "${s}" =~ ^([0-9]+(\.[0-9]+)?)([[:space:]]*)(B|KB|MB|GB|TB|PB)$ ]]; then
        local n="${BASH_REMATCH[1]}"
        local u="${BASH_REMATCH[4]}"
        case "${u}" in
            B)  echo "${n%.*}" ;;
            KB) awk "BEGIN{printf \"%d\", ${n}*1}" ;;
            MB) awk "BEGIN{printf \"%d\", ${n}}" ;;
            GB) awk "BEGIN{printf \"%d\", ${n}*1024}" ;;
            TB) awk "BEGIN{printf \"%d\", ${n}*1024*1024}" ;;
            PB) awk "BEGIN{printf \"%d\", ${n}*1024*1024*1024}" ;;
        esac
    else
        echo 0
    fi
}

case "${RESOURCE}" in
    "")
        exit 0
        ;;
    size)
        LIMIT_STR=$(jq -r '(.spec.objectStorage.totalSize // "0")' <<<"${DATA}")
        # status may be empty ({}); try common usage fields, fall back to 0
        USAGE_STR=$(jq -r '
            (.status.quotaUsage.objectStorage.totalSize //
             .status.objectStorage.totalSize // "0")' <<<"${DATA}")

        LIMIT_MB=$(to_mb "${LIMIT_STR}")
        USAGE_MB=$(to_mb "${USAGE_STR}")
        AVAIL_MB=$(( LIMIT_MB - USAGE_MB ))

        echo "Object Storage (project): ${USAGE_STR} used, limit ${LIMIT_STR}"
        if [[ -n "${NEEDED}" ]]; then
            NEEDED_MB=$(( NEEDED * 1024 ))
            if (( AVAIL_MB < NEEDED_MB )); then
                echo "Error: need ${NEEDED}GB more object storage, but only ${AVAIL_MB}MB available." >&2
                echo "To request a quota increase, contact support@evroc.com" >&2
                exit 1
            fi
            echo "${NEEDED}GB fits in remaining ${AVAIL_MB}MB"
        fi
        ;;
    *)
        echo "Error: unknown resource '${RESOURCE}'. Use: size" >&2
        exit 1
        ;;
esac
