#!/usr/bin/env bash
# evroc-auth-checker for evroc-iam

set -euo pipefail

ERR=0

if ! command -v evroc &>/dev/null; then
    echo "✗ evroc CLI not found. Install from: https://docs.evroc.com/"
    ERR=1
fi

if [[ ! -f ~/.evroc/config.yaml ]]; then
    echo "✗ ~/.evroc/config.yaml not found. Authenticate with: evroc login"
    ERR=1
else
    echo "✓ ~/.evroc/config.yaml found"
fi

# IAM operations don't strictly require a project, but warn if one is set
PROJECT=$(evroc config current-project 2>/dev/null || true)
if [[ -n "${PROJECT:-}" ]]; then
    echo "✓ Project context: ${PROJECT}"
fi

if [[ $ERR -ne 0 ]]; then
    exit 1
fi

echo "✓ All evroc auth checks passed."
