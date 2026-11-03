#!/usr/bin/env bash
# check-cli.sh — ensure the evroc CLI is installed and report upgrade availability
# Delegates to the official one-line installer at docs.evroc.com/install.sh.
# If evroc is already in PATH and working, exits immediately.
#
# If the CLI is installed but a newer release exists, prints an upgrade
# notice (via `evroc upgrade --dry-run`, which changes nothing) and STILL
# exits 0. This script never upgrades: upgrading replaces the binary the
# agent is currently executing against, so it requires explicit user
# confirmation — the SKILL.md HALT directive governs that. A dry-run
# failure (offline, download server down) is advisory-only.
#
# Usage:
#   bash scripts/check-cli.sh
set -euo pipefail

BIN_NAME="evroc"

# --- Check if already in PATH and functional ---
if command -v "${BIN_NAME}" >/dev/null 2>&1; then
    if "${BIN_NAME}" version >/dev/null 2>&1; then
        echo "${BIN_NAME} CLI already installed: $(command -v "${BIN_NAME}")" >&2
        # --- Report upgrade availability (never upgrades) ---
        # `evroc upgrade --dry-run` prints what it WOULD do; on the latest
        # version it says so and exits 0. Advisory only: offline/servers-down
        # must not fail the skill.
        if UPGRADE_OUT=$("${BIN_NAME}" upgrade --dry-run 2>&1); then
            if [[ "${UPGRADE_OUT}" == *"already on the latest version"* ]]; then
                : # nothing to do
            else
                echo "UPGRADE AVAILABLE: a newer evroc CLI release exists." >&2
                echo "Dry-run report: ${UPGRADE_OUT}" >&2
                echo "Upgrade requires explicit confirmation — ask the user before running 'evroc upgrade'." >&2
            fi
        else
            echo "Note: could not check for CLI updates ('${BIN_NAME} upgrade --dry-run' failed) — continuing." >&2
        fi
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
