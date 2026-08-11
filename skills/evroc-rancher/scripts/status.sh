#!/usr/bin/env bash
# evroc-rancher status checker
# SSHs into the Rancher server node and runs health checks.

set -euo pipefail

SERVER_IP="$1"
SSH_KEY="${2:-${HOME}/.ssh/id_ed25519}"
SSH_USER="${3:-ubuntu}"

if [[ -z "${SERVER_IP}" ]]; then
    echo "Usage: $0 <rancher_server_ip> [ssh_key_path] [ssh_user]"
    exit 1
fi

echo "Checking Rancher server at ${SERVER_IP}..."
echo ""

echo "1. cloud-init status"
ssh -o StrictHostKeyChecking=no "${SSH_USER}@${SERVER_IP}" "sudo cloud-init status" || echo "   (cloud-init not yet finishing — this is normal during bootstrap)"

echo ""
echo "2. K3s nodes"
ssh -o StrictHostKeyChecking=no "${SSH_USER}@${SERVER_IP}" "sudo k3s kubectl get nodes" || echo "   (K3s not ready yet)"

echo ""
echo "3. Rancher pods"
ssh -o StrictHostKeyChecking=no "${SSH_USER}@${SERVER_IP}" "sudo k3s kubectl -n cattle-system get pods" || echo "   (Rancher namespace not found)"

echo ""
echo "4. cert-manager pods"
ssh -o StrictHostKeyChecking=no "${SSH_USER}@${SERVER_IP}" "sudo k3s kubectl -n cert-manager get pods" || echo "   (cert-manager not yet installed)"

echo ""
echo "5. Rancher rollout status"
ssh -o StrictHostKeyChecking=no "${SSH_USER}@${SERVER_IP}" "sudo k3s kubectl -n cattle-system rollout status deploy/rancher" || echo "   (rollout not yet complete)"

echo ""
echo "Status check complete."
