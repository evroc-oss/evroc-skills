#!/usr/bin/env bash
# check-cli.sh — ensure the evroc CLI is installed
# Delegates to the official one-line installer at docs.evroc.com/install.sh.
# If evroc is already in PATH and working, exits immediately.
#
# Usage:
#   bash scripts/check-cli.sh
set -euo pipefail

BIN_NAME="evroc"

# --- Check if already in PATH and functional ---
if command -v "${BIN_NAME}" >/dev/null 2>&1; then
    if "${BIN_NAME}" version >/dev/null 2>&1; then
        echo "${BIN_NAME} CLI already installed: $(command -v "${BIN_NAME}")" >&2
        exit 0
    fi
fi

# --- Delegate to official installer ---
echo "Installing evroc CLI via official installer..." >&2
curl -fsSL https://docs.evroc.com/install.sh | bash

# --- Verify ---
if ! command -v "${BIN_NAME}" >/dev/null 2>&1; then
    # Installer may have written to ~/.local/bin which isn't in PATH yet
    INSTALL_PATH="${HOME}/.local/bin/${BIN_NAME}"
    if [ -x "${INSTALL_PATH}" ]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
fi

if command -v "${BIN_NAME}" >/dev/null 2>&1; then
    echo "${BIN_NAME} CLI installed: $(command -v "${BIN_NAME}")" >&2
    "${BIN_NAME}" version >&2
    exit 0
else
    echo "Error: ${BIN_NAME} CLI not found after install." >&2
    echo "  The installer may have added ~/.local/bin to your PATH." >&2
    echo "  Run: source ~/.bashrc  (or ~/.zshrc), then try again." >&2
    exit 1
fi
