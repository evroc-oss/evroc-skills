#!/usr/bin/env bash
# evroc-rancher prerequisites checker
# Checks tools, auth, project, and SSH key setup.

set -euo pipefail

ERR=0

# --- 1. Terraform ---
if command -v terraform &>/dev/null; then
    echo "✓ terraform found: $(terraform version -json | jq -r '.terraform_version')"
else
    echo "✗ terraform not found. Installing via Homebrew..."
    if command -v brew &>/dev/null; then
        brew install terraform
    else
        echo "  Homebrew not found. Install Terraform manually: https://developer.hashicorp.com/terraform/install"
        ERR=1
    fi
fi

# --- 2. evroc CLI ---
# Auto-install via check-cli.sh if evroc is missing.
# Ensure PATH includes ~/.local/bin for this session.
if [[ -d "${HOME}/.local/bin" && ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    export PATH="${HOME}/.local/bin:${PATH}"
fi

if bash scripts/check-cli.sh 2>&1; then
    echo "✓ evroc CLI verified"
else
    echo "✗ evroc CLI not found and installation failed"
    ERR=1
fi

# --- 3. evroc auth & project ---
if [[ -f ~/.evroc/config.yaml ]]; then
    echo "✓ ~/.evroc/config.yaml exists"
    PROJECT=$(evroc config current-project 2>/dev/null || true)
    if [[ -z "${PROJECT:-}" ]]; then
        echo "⚠ No project set. Attempting auto-detection..."
        PROJECT=$(evroc iam project list -o json 2>/dev/null | jq -r '.[0].projectId // empty')
        if [[ -n "${PROJECT:-}" ]]; then
            echo "  Auto-selected project: ${PROJECT}"
            evroc config set-project "${PROJECT}"
            echo "  ✓ Project set via evroc config set-project"
        else
            echo "  ✗ No projects available. Create one: evroc iam project create my-project"
            ERR=1
        fi
    else
        echo "✓ Current project: ${PROJECT}"
    fi
else
    echo "✗ ~/.evroc/config.yaml not found. Run: evroc login"
    ERR=1
fi

# --- 4. SSH key ---
if [[ -n "${SSH_PUBLIC_KEY:-}" ]]; then
    echo "✓ SSH_PUBLIC_KEY env var set (passed from caller)"
elif [[ -f ~/.ssh/id_ed25519.pub ]] || [[ -f ~/.ssh/id_rsa.pub ]]; then
    echo "✓ SSH public key found in ~/.ssh/"
else
    echo "⚠ No SSH public key found. Generate one: ssh-keygen -t ed25519 -C 'rancher@evroc'"
fi

# --- 5. curl, jq, git ---
for tool in curl jq git; do
    if command -v "${tool}" &>/dev/null; then
        echo "✓ ${tool} found"
    else
        echo "✗ ${tool} not found. Install it."
        ERR=1
    fi
done

if [[ $ERR -ne 0 ]]; then
    echo ""
    echo "Some prerequisites are missing. Fix the issues above and re-run."
    exit 1
fi

echo ""
echo "✓ All prerequisites met."
