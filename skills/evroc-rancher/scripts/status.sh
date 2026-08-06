#!/usr/bin/env bash
# status.sh — check deployment status (cloud-init, K3s, Rancher pods)
# Usage: status.sh <rancher_node_ip>
set -euo pipefail

IP="$1"

if [ -z "$IP" ]; then
  echo "Usage: status.sh <rancher_node_ip>"
  exit 1
fi

echo "=== Cloud-init status ==="
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "ubuntu@$IP" "sudo cloud-init status" 2>/dev/null || echo "Cannot SSH to $IP"

echo ""
echo "=== K3s nodes ==="
ssh -o ConnectTimeout=10 "ubuntu@$IP" "sudo k3s kubectl get nodes" 2>/dev/null || echo "K3s not ready yet"

echo ""
echo "=== Rancher pods ==="
ssh -o ConnectTimeout=10 "ubuntu@$IP" "sudo k3s kubectl -n cattle-system get pods" 2>/dev/null || echo "Rancher not ready yet"

echo ""
echo "=== cert-manager pods ==="
ssh -o ConnectTimeout=10 "ubuntu@$IP" "sudo k3s kubectl -n cert-manager get pods" 2>/dev/null || echo "cert-manager not ready yet"
