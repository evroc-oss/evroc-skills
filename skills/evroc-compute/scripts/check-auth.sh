#!/usr/bin/env bash
# evroc-auth-checker
# Verifies the evroc CLI is installed, authenticated, and a project is set.
# Use as a gate before running any evroc-dependent skill.

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

PROJECT=$(evroc config current-project 2>/dev/null || true)
if [[ -z "${PROJECT:-}" ]]; then
    echo "✗ No project set in evroc config. Run: evroc config set-project <project>"
    ERR=1
else
    echo "✓ Current project: ${PROJECT}"
fi

if [[ $ERR -ne 0 ]]; then
    exit 1
fi

echo "✓ All evroc auth checks passed."
