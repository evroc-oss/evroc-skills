#!/usr/bin/env bash
# destroy.sh — destroy the Rancher on evroc deployment
# Usage: destroy.sh <workdir>
set -euo pipefail

WORKDIR="${1:-.}"

if [ ! -f "$WORKDIR/main.tf" ]; then
  echo "ERROR: No Terraform files found in $WORKDIR"
  exit 1
fi

cd "$WORKDIR"
terraform destroy -auto-approve
echo ""
echo "=== Destroy Complete ==="
