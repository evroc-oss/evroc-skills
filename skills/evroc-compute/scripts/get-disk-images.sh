#!/usr/bin/env bash
# scripts/get-disk-images.sh
# Fetches the live list of evroc compute disk images from the API.
# Fragile op: external API call + auth token lifecycle.
#
# Prerequisites: evroc CLI authenticated (evroc login).
# Requires: curl, jq

set -euo pipefail

TOKEN=$(evroc iam get-access-token --format=json 2>/dev/null | jq -r '.token // empty')

if [[ -z "$TOKEN" ]]; then
    echo "Error: Failed to get access token." >&2
    echo "Run: evroc login" >&2
    exit 1
fi

ENDPOINT="https://api.evroc.com/compute/v1beta2/global/diskImages/evroc"

curl -fsSL \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/json" \
    "${ENDPOINT}" \
    | jq -r '.diskImages[] | "\(.name)\t\(.description // "")"' 2>/dev/null \
    || { echo "Error: Failed to fetch disk images from ${ENDPOINT}" >&2; exit 1; }
