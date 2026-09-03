#!/usr/bin/env bash
# check-cli.sh — evroc CLI installer for agent skills
# Ensures the evroc binary is in PATH. If missing, downloads latest for the
# current OS/arch into ~/.local/bin, verifies checksum, and exports PATH.
#
# No sudo. No RC file edits. Non-interactive. Exits non-zero on any failure.
#
# Usage:
#   bash scripts/check-cli.sh

set -euo pipefail

BIN_NAME="evroc"
INSTALL_DIR="${HOME}/.local/bin"
INSTALL_PATH="${INSTALL_DIR}/${BIN_NAME}"
DOWNLOAD_BASE="https://downloads.cloud.evroc.com/evroc-cli/latest"

# --- Check if already in PATH ---
if command -v "${BIN_NAME}" >/dev/null 2>&1; then
    if "${BIN_NAME}" --version >/dev/null 2>&1; then
        echo "${BIN_NAME} CLI already installed: $(command -v "${BIN_NAME}")" >&2
        exit 0
    fi
fi

# --- Detect platform ---
OS=$(uname -s)
ARCH=$(uname -m)

case "${OS}" in
    Darwin) OS="darwin" ;;
    Linux)  OS="linux" ;;
    *)
        echo "Error: Unsupported OS: ${OS}. Only Darwin and Linux are supported." >&2
        exit 1
        ;;
esac

case "${ARCH}" in
    x86_64|amd64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)
        echo "Error: Unsupported architecture: ${ARCH}" >&2
        exit 1
        ;;
esac

PLATFORM="${OS}_${ARCH}"
BINARY_URL="${DOWNLOAD_BASE}/${PLATFORM}/${BIN_NAME}"
CHECKSUM_URL="${BINARY_URL}.sha256"

# --- Prepare temp dir ---
TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf "${TEMP_DIR}"; }
trap cleanup EXIT

# --- Download binary ---
echo "Downloading ${BIN_NAME} CLI (${PLATFORM})..." >&2
curl -fsSL -o "${TEMP_DIR}/${BIN_NAME}" "${BINARY_URL}"

# --- Download and verify checksum ---
if curl -fsSL -o "${TEMP_DIR}/${BIN_NAME}.sha256" "${CHECKSUM_URL}" 2>/dev/null; then
    if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL=$(sha256sum "${TEMP_DIR}/${BIN_NAME}" | awk '{print $1}')
    else
        ACTUAL=$(shasum -a 256 "${TEMP_DIR}/${BIN_NAME}" | awk '{print $1}')
    fi
    EXPECTED=$(awk '{print $1}' "${TEMP_DIR}/${BIN_NAME}.sha256")

    if [[ -n "${EXPECTED}" && -n "${ACTUAL}" && "${EXPECTED}" == "${ACTUAL}" ]]; then
        echo "Checksum verified." >&2
    else
        echo "Error: Checksum verification failed." >&2
        echo "  Expected: ${EXPECTED:-empty}" >&2
        echo "  Actual:   ${ACTUAL:-empty}" >&2
        exit 1
    fi
else
    echo "Warning: No checksum available, skipping verification." >&2
fi

# --- Install ---
mkdir -p "${INSTALL_DIR}"
mv "${TEMP_DIR}/${BIN_NAME}" "${INSTALL_PATH}"
chmod +x "${INSTALL_PATH}"

# --- Export PATH for current session ---
if [[ ":${PATH}:" != *":${INSTALL_DIR}:"* ]]; then
    export PATH="${INSTALL_DIR}:${PATH}"
fi

# --- Verify ---
if ! "${INSTALL_PATH}" --version >/dev/null 2>&1; then
    echo "Error: Installed binary does not run. Path: ${INSTALL_PATH}" >&2
    exit 1
fi

echo "${BIN_NAME} CLI installed to ${INSTALL_PATH}" >&2
"${INSTALL_PATH}" --version >&2
exit 0
