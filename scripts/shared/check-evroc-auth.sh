#!/usr/bin/env bash
# evroc-auth-checker — shared auth gate for all evroc skills.
# Verifies the evroc CLI is installed, authenticated, and (optionally) a project is set.
# Use as a gate before running any evroc-dependent skill.
#
# Usage:
#   bash scripts/check-auth.sh                   # project required (default)
#   bash scripts/check-auth.sh --require-project # explicitly require project
#   EVROC_REQUIRE_PROJECT=false bash scripts/check-auth.sh  # project optional (e.g. IAM, Think)
#
# Each skill's scripts/check-auth.sh should be a thin wrapper:
#   #!/usr/bin/env bash
#   exec bash "$(dirname "$0")/../../scripts/shared/check-evroc-auth.sh" "$@"
# Or for skills where project is optional:
#   #!/usr/bin/env bash
#   exec bash "$(dirname "$0")/../../scripts/shared/check-evroc-auth.sh" --project-optional "$@"

set -euo pipefail

ERR=0
REQUIRE_PROJECT=true

# Parse args
for arg in "$@"; do
  case "$arg" in
    --require-project) REQUIRE_PROJECT=true ;;
    --project-optional) REQUIRE_PROJECT=false ;;
  esac
done

# Also check env var override
if [[ "${EVROC_REQUIRE_PROJECT:-}" == "false" ]]; then
  REQUIRE_PROJECT=false
fi

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
    if $REQUIRE_PROJECT; then
        echo "✗ No project set in evroc config. Run: evroc config set-project <project>"
        ERR=1
    else
        echo "⚠ No project set. Some operations may auto-create one. Set explicitly with: evroc config set-project <project>"
    fi
else
    echo "✓ Current project: ${PROJECT}"
fi

if [[ $ERR -ne 0 ]]; then
    exit 1
fi

echo "✓ All evroc auth checks passed."
