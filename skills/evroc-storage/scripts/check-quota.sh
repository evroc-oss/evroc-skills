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

# Guard explicitly: under set -e an unguarded $(...) would abort the script
# silently (stderr swallowed), producing no diagnosis at all.
if ! DATA=$(evroc quotas projectquotas get -o json 2>/dev/null); then
    echo "Error: could not fetch project quotas — the evroc CLI call failed." >&2
    echo "Check auth with 'evroc login', or run 'evroc quotas projectquotas get' to see the raw error." >&2
    exit 1
fi

# Show the human-readable table (single CLI call, goes to stdout)
evroc quotas projectquotas get 2>/dev/null || true

# Normalize a size string like "10TB", "512GB", "100MB", "0" to MB (integer).
# Fails LOUD on unparseable input: silently treating an unknown string as 0
# would make AVAIL = LIMIT - 0 and false-pass a needed-check. Plain "0" and
# "" are accepted (no usage reported yet) — any other unparseable string is fatal.
to_mb() { # to_mb <string> <output-var>
    local input="${1:-}"
    local outvar="$2"
    if [[ "${input}" =~ ^([0-9]+(\.[0-9]+)?)([[:space:]]*)(B|KB|MB|GB|TB|PB)$ ]]; then
        local n="${BASH_REMATCH[1]}"
        local u="${BASH_REMATCH[4]}"
        local mult=1
        case "${u}" in
            B)  mult=0 ;;
            KB) mult=1 ;;
            MB) mult=1024 ;;
            GB) mult=$(( 1024 * 1024 )) ;;
            TB) mult=$(( 1024 * 1024 * 1024 )) ;;
            PB) mult=$(( 1024 * 1024 * 1024 * 1024 )) ;;
        esac
        if (( mult == 0 )); then
            printf -v "${outvar}" '%d' "${n%.*}"   # bytes: truncate to whole MB
        else
            printf -v "${outvar}" '%d' "$(awk -v n="${n}" -v m="${mult}" 'BEGIN{printf "%.0f", n*m/1024}')"
        fi
    elif [[ -z "${input}" || "${input}" == "0" ]]; then
        printf -v "${outvar}" '%d' 0
    else
        echo "Error: cannot parse size '${input}' (expected e.g. 10TB, 512GB, 100MB)." >&2
        echo "Not comparing against a quota we cannot measure — refusing to guess." >&2
        exit 1
    fi
}

# Render MB as a human-readable size, unit-consistent with NEEDED (GB input).
mb_to_hr() { # mb_to_hr <mb>
    local mb="$1"
    local num unit
    if (( mb >= 1024 * 1024 )); then
        num="$(awk -v m="${mb}" 'BEGIN{printf "%.1f", m/1024/1024}')"; unit="TB"
    elif (( mb >= 1024 )); then
        num="$(awk -v m="${mb}" 'BEGIN{printf "%.1f", m/1024}')"; unit="GB"
    else
        num="${mb}"; unit="MB"
    fi
    num="${num%.*}"   # strip trailing .0 (values are integral MB at these magnitudes)
    echo "${num}${unit}"
}

case "${RESOURCE}" in
    "")
        exit 0
        ;;
    size)
        LIMIT_STR=$(jq -r '(.spec.objectStorage.totalSize // "")' <<<"${DATA}")
        # status may be empty ({}); try common usage fields, fall back to 0
        USAGE_STR=$(jq -r '
            (.status.quotaUsage.objectStorage.totalSize //
             .status.objectStorage.totalSize // "0")' <<<"${DATA}")

        to_mb "${LIMIT_STR}" LIMIT_MB
        to_mb "${USAGE_STR}" USAGE_MB
        AVAIL_MB=$(( LIMIT_MB - USAGE_MB ))

        echo "Object Storage (project): ${USAGE_STR} used, limit ${LIMIT_STR}"
        if [[ -n "${NEEDED}" ]]; then
            NEEDED_MB=$(( NEEDED * 1024 ))
            if (( AVAIL_MB < NEEDED_MB )); then
                echo "Error: need ${NEEDED}GB more object storage, but only $(mb_to_hr "${AVAIL_MB}") available." >&2
                echo "To request a quota increase, contact support@evroc.com" >&2
                exit 1
            fi
            echo "${NEEDED}GB fits in remaining $(mb_to_hr "${AVAIL_MB}")"
        fi
        ;;
    *)
        echo "Error: unknown resource '${RESOURCE}'. Use: size" >&2
        exit 1
        ;;
esac
