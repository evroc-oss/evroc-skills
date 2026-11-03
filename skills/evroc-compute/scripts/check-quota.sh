#!/usr/bin/env bash
# evroc-compute QUOTA CHECKER
# Checks real organization quota usage from the API instead of hardcoded limits.
#
# Usage:
#   bash scripts/check-quota.sh                       # show all org quotas (table)
#   bash scripts/check-quota.sh vcpus [N]             # exit 1 if fewer than N vCPUs available
#   bash scripts/check-quota.sh memory [N_GB]         # exit 1 if fewer than N GB available
#   bash scripts/check-quota.sh blockstorage [N_GB]   # exit 1 if fewer than N GB available
#   bash scripts/check-quota.sh gpus [N]              # exit 1 if no GPU model has N available
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

# Parse a size string like "10TB", "932.5GB", "100MB" to whole GB (decimal units).
# Fails LOUD on unparseable input — treating an unknown string as a number
# would silently produce a wrong quota verdict.
str_to_gb() { # str_to_gb <string> <output-var>
    local input="${1:-}"
    local outvar="$2"
    if [[ "${input}" =~ ^([0-9]+(\.[0-9]+)?)([[:space:]]*)(B|KB|MB|GB|TB|PB)$ ]]; then
        local n="${BASH_REMATCH[1]}"
        local u="${BASH_REMATCH[4]}"
        case "${u}" in
            B)  n="$(awk -v n="${n}" 'BEGIN{printf "%.9g", n/1000000000}')" ;;
            KB) n="$(awk -v n="${n}" 'BEGIN{printf "%.9g", n/1000000}')" ;;
            MB) n="$(awk -v n="${n}" 'BEGIN{printf "%.9g", n/1000}')" ;;
            GB) : ;;
            TB) n="$(awk -v n="${n}" 'BEGIN{printf "%.9g", n*1000}')" ;;
            PB) n="$(awk -v n="${n}" 'BEGIN{printf "%.9g", n*1000000}')" ;;
        esac
        # round to nearest GB (display string has at most one decimal)
        case "${u}" in
            GB) printf -v "${outvar}" '%d' "${n%%.*}" ;;
            *)  printf -v "${outvar}" '%d' "$(awk -v n="${n}" 'BEGIN{printf "%.0f", n}')" ;;
        esac
    else
        echo "Error: cannot parse size '${input}' (expected e.g. 10TB, 932.5GB, 100MB)." >&2
        echo "Not comparing against a quota we cannot measure — refusing to guess." >&2
        exit 1
    fi
}

# Memory usage: the API provides a numeric helper field. NOTE: the field is
# named memoryInKiBs, but empirically dividing by 1e6 reproduces the CLI's own
# displayed value (932512000 -> "932.5GB") — the display treats it as decimal
# KB. We match display semantics so the numbers agree with the table above.
# If the numeric field is absent, parse the display string instead (fails
# loud if even that is unparseable — never guess a quota number).
mem_usage_gb() {
    local kiBs hr
    kiBs=$(jq -r '(.status.quotaUsage.compute.memoryInKiBs // 0)' <<<"${DATA}")
    if [[ "${kiBs}" =~ ^[0-9]+$ ]] && (( kiBs > 0 )); then
        awk -v k="${kiBs}" 'BEGIN{printf "%d", k/1000000}'
    else
        hr=$(jq -r '(.status.quotaUsage.compute.memory // "0")' <<<"${DATA}")
        str_to_gb "${hr}" MEMGB
        echo "${MEMGB}"
    fi
}

# Block storage usage: numeric helper field blockStorageInMBs, decimal MB
# (7723000 -> "7.7TB" in the CLI table; divide by 1000 for GB).
bs_usage_gb() {
    local mbs hr
    mbs=$(jq -r '(.status.quotaUsage.compute.blockStorageInMBs // 0)' <<<"${DATA}")
    if [[ "${mbs}" =~ ^[0-9]+$ ]] && (( mbs > 0 )); then
        awk -v m="${mbs}" 'BEGIN{printf "%d", m/1000}'
    else
        hr=$(jq -r '(.status.quotaUsage.compute.blockStorage // "0")' <<<"${DATA}")
        str_to_gb "${hr}" BSGB
        echo "${BSGB}"
    fi
}

check_gb() { # check_gb <label> <limit-string> <usage-GB> [needed-GB]
    local label="$1" limit_str="$2" used_gb="$3" needed_gb="${4:-}"
    local limit_gb avail_gb
    if [[ -z "${limit_str}" || "${limit_str}" == "0" ]]; then
        echo "${label}: no quota limit configured (unlimited)${needed_gb:+ — ${needed_gb}GB requested}"
        return 0
    fi
    str_to_gb "${limit_str}" limit_gb
    avail_gb=$(( limit_gb - used_gb ))
    echo "${label}: ${used_gb}GB used, limit ${limit_str} (${avail_gb}GB available)"
    if [[ -n "${needed_gb}" ]] && (( avail_gb < needed_gb )); then
        echo "Error: need ${needed_gb}GB ${label}, but only ${avail_gb}GB available (limit ${limit_str})." >&2
        echo "To request a quota increase, contact support@evroc.com" >&2
        exit 1
    fi
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
    local model used lim avail any_ok=0 rows=0
    echo "GPUs:"
    # union of models in quota spec and usage; one row each (limit, usage)
    while IFS=$'\t' read -r model lim used; do
        rows=$(( rows + 1 ))
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
    if [[ -n "${needed}" ]]; then
        if (( rows == 0 )); then
            echo "Error: need ${needed} GPUs, but no GPU quota is configured for this organization." >&2
            echo "To request a GPU quota, contact support@evroc.com" >&2
            exit 1
        fi
        if (( any_ok == 0 )); then
            echo "Error: need ${needed} GPUs, but every model with quota is exhausted." >&2
            echo "To request a quota increase, contact support@evroc.com" >&2
            exit 1
        fi
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
        check_gb "Memory" \
            "$(jq -r '(.spec.quotas.compute.memory // "")' <<<"${DATA}")" \
            "$(mem_usage_gb)" \
            "${NEEDED}"
        ;;
    blockstorage)
        check_gb "Block Storage" \
            "$(jq -r '(.spec.quotas.compute.blockStorage // "")' <<<"${DATA}")" \
            "$(bs_usage_gb)" \
            "${NEEDED}"
        ;;
    gpus)
        check_gpus "${NEEDED}"
        ;;
    all)
        check_numeric "vCPUs" compute vCPUs
        check_gpus
        check_gb "Memory" \
            "$(jq -r '(.spec.quotas.compute.memory // "")' <<<"${DATA}")" \
            "$(mem_usage_gb)"
        check_gb "Block Storage" \
            "$(jq -r '(.spec.quotas.compute.blockStorage // "")' <<<"${DATA}")" \
            "$(bs_usage_gb)"
        ;;
    *)
        echo "Error: unknown resource '${RESOURCE}'. Use: vcpus | memory | blockstorage | gpus | all" >&2
        exit 1
        ;;
esac
