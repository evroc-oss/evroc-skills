#!/usr/bin/env bash
# deploy.sh — deploy Rancher on evroc using the bundled Terraform module
# Usage: deploy.sh <workdir> <ssh_public_key> <rancher_admin_password> [evroc_region] [evroc_zone] [prefix]
set -euo pipefail

WORKDIR="$1"
SSH_PUBLIC_KEY="$2"
RANCHER_PASSWORD="$3"
EVROC_REGION="${4:-se-sto}"
EVROC_ZONE="${5:-a}"
PREFIX="${6:-rancher}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"
TFVARS="$WORKDIR/terraform.tfvars"

# --- Stage assets into workdir ---
mkdir -p "$WORKDIR"
cp "$ASSETS_DIR"/main.tf "$ASSETS_DIR"/variables.tf "$ASSETS_DIR"/cloud-init-rancher.yaml "$ASSETS_DIR"/cloud-init-workload.yaml "$ASSETS_DIR"/terraform.tfvars.example "$WORKDIR/"

# --- Write terraform.tfvars ---
cat > "$TFVARS" << EOF
ssh_public_key = "$SSH_PUBLIC_KEY"
rancher_server_admin_password = "$RANCHER_PASSWORD"
evroc_region = "$EVROC_REGION"
evroc_zone = "$EVROC_ZONE"
prefix = "$PREFIX"
EOF

# --- Terraform init + apply ---
cd "$WORKDIR"
terraform init
terraform apply -auto-approve

# --- Output results ---
echo ""
echo "=== Deployment Complete ==="
terraform output rancher_node_ip
terraform output rancher_server_url
terraform output workload_node_ip
