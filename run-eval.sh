#!/usr/bin/env bash
# Run skillgrade against the evroc-compute eval suite.
# Prepends the mock evroc CLI (tests/bin) to PATH so the agent invokes the
# mock instead of the real, authenticated evroc CLI.
set -euo pipefail
cd "$(dirname "$0")"
REPO="$(pwd)"
export PATH="$REPO/tests/bin:$PATH"

# sanity: confirm the mock shadows any real evroc
EVROC_BIN="$(command -v evroc || true)"
echo "evroc on PATH: $EVROC_BIN"
if [ "$EVROC_BIN" != "$REPO/tests/bin/evroc" ]; then
  echo "WARNING: evroc does not resolve to the mock shim at $REPO/tests/bin/evroc" >&2
fi

exec skillgrade \
  --agent=opencode \
  --opencode-model=evroc/zai-org/GLM-5.2 \
  --provider=local \
  --smoke \
  --output="$REPO/tests/.skillgrade-out" \
  "$@"
