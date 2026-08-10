#!/usr/bin/env bash
# prerequisites.sh — check and install tools needed for Rancher on evroc deployment
# Exits 0 if all prerequisites met (after any installs), 1 if manual action needed.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
need() { echo -e "${RED}[NEEDED]${NC} $1"; }

NEEDS_MANUAL=0

# --- Terraform ---
if command -v terraform >/dev/null 2>&1; then
  ok "Terraform installed: $(terraform version -json 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])' 2>/dev/null || terraform version | head -1)"
elif command -v brew >/dev/null 2>&1; then
  warn "Terraform not found. Installing via Homebrew..."
  brew install terraform
  if command -v terraform >/dev/null 2>&1; then
    ok "Terraform installed via Homebrew"
  else
    fail "Terraform install failed. Install manually: https://developer.hashicorp.com/terraform/install"
    NEEDS_MANUAL=1
  fi
else
  need "Terraform not installed and Homebrew not found. Install manually: https://developer.hashicorp.com/terraform/install"
  NEEDS_MANUAL=1
fi

# --- evroc CLI ---
if command -v evroc >/dev/null 2>&1; then
  ok "evroc CLI installed: $(evroc version 2>/dev/null || echo 'present')"
else
  need "evroc CLI not installed. Install from: https://docs.evroc.com/cli.html"
  NEEDS_MANUAL=1
fi

# --- evroc authentication ---
if [ -f "$HOME/.evroc/config.yaml" ]; then
  ok "evroc credentials found at ~/.evroc/config.yaml"
else
  need "evroc not authenticated. Run: evroc login"
  NEEDS_MANUAL=1
fi

# --- evroc project set ---
if [ -f "$HOME/.evroc/config.yaml" ]; then
  CURRENT_PROJECT=$(evroc config current-project 2>/dev/null || echo "")
  if [ -z "$CURRENT_PROJECT" ]; then
    # Try to auto-detect and set the project
    AVAILABLE_PROJECTS=$(evroc iam project list 2>/dev/null || echo "")
    if [ -n "$AVAILABLE_PROJECTS" ]; then
      FIRST_PROJECT=$(echo "$AVAILABLE_PROJECTS" | head -1)
      warn "No project set. Auto-detecting: $FIRST_PROJECT"
      evroc config set-project "$FIRST_PROJECT" 2>/dev/null && ok "Project set to: $FIRST_PROJECT" || {
        need "Could not auto-set project. Run: evroc config set-project <project-name>"
        NEEDS_MANUAL=1
      }
    else
      need "No project set and none detected. Run: evroc config set-project <project-name>"
      NEEDS_MANUAL=1
    fi
  else
    ok "evroc project set: $CURRENT_PROJECT"
  fi
fi

# --- SSH key ---
SSH_KEY=""
for keyfile in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
  if [ -f "$keyfile" ]; then
    SSH_KEY=$(cat "$keyfile")
    ok "SSH public key found: $keyfile"
    break
  fi
done
if [ -z "$SSH_KEY" ]; then
  need "No SSH public key found. Generate one: ssh-keygen -t ed25519 -C \"your-email@example.com\""
  NEEDS_MANUAL=1
fi

# --- curl ---
if command -v curl >/dev/null 2>&1; then
  ok "curl available"
else
  need "curl not found (required by cloud-init scripts)"
  NEEDS_MANUAL=1
fi

# --- git ---
if command -v git >/dev/null 2>&1; then
  ok "git available"
else
  need "git not found"
  NEEDS_MANUAL=1
fi

echo ""
if [ "$NEEDS_MANUAL" -eq 0 ]; then
  ok "All prerequisites met."
  exit 0
else
  fail "Manual action required. Resolve the [NEEDED] items above, then re-run."
  exit 1
fi
