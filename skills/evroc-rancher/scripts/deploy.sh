#!/usr/bin/env bash
# evroc-rancher deployment script
# Copies Terraform assets into a work directory and applies them.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="${SCRIPT_DIR}/../assets"

WORKDIR="$1"          # Target directory where Terraform runs
SSH_KEY="$2"          # SSH public key string (not a file path)
PASSWORD="$3"
REGION="${4:-se-sto}"
ZONE="${5:-a}"
PREFIX="${6:-rancher}"
WORKLOAD_COUNT="${7:-1}"

if [[ -z "${WORKDIR}" ]] || [[ -z "${SSH_KEY}" ]] || [[ -z "${PASSWORD}" ]]; then
    echo "Usage: $0 <workdir> '<ssh_public_key>' '<rancher_admin_password>' [region] [zone] [prefix] [workload_count]"
    exit 1
fi

if [[ ${#PASSWORD} -lt 14 ]]; then
    echo "Error: Rancher admin password must be at least 14 characters."
    exit 1
fi

# Generate a secure K3s token if not provided
K3S_TOKEN="${K3S_TOKEN:-$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)}"

mkdir -p "${WORKDIR}"

# Copy assets
rsync -av "${ASSETS_DIR}/" "${WORKDIR}/" 2>/dev/null || cp -r "${ASSETS_DIR}"/* "${WORKDIR}/"

# Write terraform.tfvars
cat > "${WORKDIR}/terraform.tfvars" <<EOF
evroc_region = "${REGION}"
evroc_zone   = "${ZONE}"
prefix       = "${PREFIX}"
ssh_public_key = "${SSH_KEY}"
rancher_server_admin_password = "${PASSWORD}"
workload_node_count = ${WORKLOAD_COUNT}
k3s_token = "${K3S_TOKEN}"
EOF

echo "******************************************************"
echo "  Rancher on evroc — Terraform assets prepared"
echo "  Work directory: ${WORKDIR}"
echo "  Region: ${REGION}, Zone: ${ZONE}"
echo "  Prefix: ${PREFIX}"
echo "  Workload nodes: ${WORKLOAD_COUNT}"
echo "******************************************************"

# Run terraform
cd "${WORKDIR}"
echo ""
echo "[1/2] terraform init (downloading providers)..."
terraform init

echo ""
echo "[2/2] terraform apply (provisioning VMs + cloud-init)..."
echo "    This will take ~5–8 minutes for VMs, then ~5–10 minutes for Rancher bootstrap."
echo ""
terraform apply -auto-approve

echo ""
echo "======================================================"
echo "  🎉 Rancher deployed!"
echo "======================================================"
echo "  Rancher URL: $(terraform output -raw rancher_server_url 2>/dev/null || echo 'unknown')"
echo "  Server IP:   $(terraform output -raw rancher_node_ip 2>/dev/null || echo 'unknown')"
echo "  Password:    (the one you provided)"
echo ""
echo "  To check status: bash status.sh <server_ip>"
echo "  To destroy:      bash destroy.sh ${WORKDIR}"
echo "======================================================"
