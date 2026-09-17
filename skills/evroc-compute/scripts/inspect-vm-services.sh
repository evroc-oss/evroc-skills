#!/usr/bin/env bash
# Pre-deletion inspection: lists running services on a VM before it's deleted.
# Tries SSH first (remote agent). If the agent is running ON the VM, runs locally.
# If SSH fails (VM stopped, no key, firewall), exits 0 with a note — non-blocking.
set -euo pipefail

VM_NAME="${1:-}"
SSH_USER="${2:-evroc-user}"
SSH_KEY="${3:-}"  # optional path to private key

if [[ -z "${VM_NAME}" ]]; then
    echo "Usage: $0 <vm-name> [ssh-user] [ssh-key-path]" >&2
    exit 1
fi

# 1. Get VM details — extract IPs
VM_JSON=$(evroc compute vm get "${VM_NAME}" -o json 2>/dev/null || true)

if [[ -z "${VM_JSON}" ]]; then
    echo "Could not retrieve VM '${VM_NAME}' — it may not exist." >&2
    exit 1
fi

# Check if VM is running
VM_STATUS=$(echo "${VM_JSON}" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('status', {}).get('virtualMachineStatus', ''))
except: print('')
" 2>/dev/null || echo "")

if [[ "${VM_STATUS}" != "Running" ]]; then
    echo "VM is not running (status: ${VM_STATUS:-unknown}). Cannot inspect services." >&2
    echo "Skipping service inspection — proceed with standard deletion warning." >&2
    exit 0
fi

# Extract public and private IPs from the VM JSON
# The network interfaces are in status.networkInterfaces[]
PUBLIC_IP=$(echo "${VM_JSON}" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for ni in d.get('status', {}).get('networkInterfaces', []):
        for ip in ni.get('ipAddresses', []):
            addr = ip.get('address', '')
            if ':' in addr:  # IPv6
                continue
            if not addr.startswith(('10.', '172.', '192.168.')):
                print(addr)
                sys.exit(0)
except: pass
" 2>/dev/null || echo "")

PRIVATE_IP=$(echo "${VM_JSON}" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for ni in d.get('status', {}).get('networkInterfaces', []):
        for ip in ni.get('ipAddresses', []):
            addr = ip.get('address', '')
            if addr.startswith(('10.', '172.', '192.168.')):
                print(addr)
                sys.exit(0)
except: pass
" 2>/dev/null || echo "")

# 2. Check if we're running ON this VM (self-destruction check)
LOCAL_HOSTNAME=$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo "")
LOCAL_IPS=$(hostname -I 2>/dev/null || ip addr show 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || echo "")

SELF_DESTRUCTION=false
for ip in ${LOCAL_IPS}; do
    if [[ "${ip}" == "${PUBLIC_IP}" ]] || [[ "${ip}" == "${PRIVATE_IP}" ]]; then
        SELF_DESTRUCTION=true
        break
    fi
done

# 3. Gather running services
SERVICES_OUTPUT=""

if [[ "${SELF_DESTRUCTION}" == "true" ]]; then
    # Agent is running on the VM — run locally, no SSH needed
    SERVICES_OUTPUT=$(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null || echo "")
elif [[ -n "${PUBLIC_IP}" ]]; then
    # Try SSH to the VM
    SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes"
    if [[ -n "${SSH_KEY}" ]]; then
        SSH_OPTS="${SSH_OPTS} -i ${SSH_KEY}"
    fi

    # Clear stale known_hosts entry for this IP
    ssh-keygen -R "${PUBLIC_IP}" 2>/dev/null || true

    SERVICES_OUTPUT=$(ssh ${SSH_OPTS} "${SSH_USER}@${PUBLIC_IP}" \
        'systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null' 2>/dev/null || echo "")

    # If public IP SSH failed and we have a private IP, try that (same network)
    if [[ -z "${SERVICES_OUTPUT}" && -n "${PRIVATE_IP}" ]]; then
        SERVICES_OUTPUT=$(ssh ${SSH_OPTS} "${SSH_USER}@${PRIVATE_IP}" \
            'systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null' 2>/dev/null || echo "")
    fi
elif [[ -n "${PRIVATE_IP}" ]]; then
    # No public IP, try private IP via SSH
    SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes"
    if [[ -n "${SSH_KEY}" ]]; then
        SSH_OPTS="${SSH_OPTS} -i ${SSH_KEY}"
    fi
    SERVICES_OUTPUT=$(ssh ${SSH_OPTS} "${SSH_USER}@${PRIVATE_IP}" \
        'systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null' 2>/dev/null || echo "")
fi

# 4. Also check for Docker containers if docker is available
DOCKER_OUTPUT=""
if [[ "${SELF_DESTRUCTION}" == "true" ]]; then
    DOCKER_OUTPUT=$(docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null || echo "")
elif [[ -n "${PUBLIC_IP}" ]] || [[ -n "${PRIVATE_IP}" ]]; then
    TARGET_IP="${PUBLIC_IP:-${PRIVATE_IP}}"
    SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes"
    if [[ -n "${SSH_KEY}" ]]; then
        SSH_OPTS="${SSH_OPTS} -i ${SSH_KEY}"
    fi
    DOCKER_OUTPUT=$(ssh ${SSH_OPTS} "${SSH_USER}@${TARGET_IP}" \
        'docker ps --format "{{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null' 2>/dev/null || echo "")
fi

# 5. Output results
echo "============================================"
echo "PRE-DELETION INSPECTION: ${VM_NAME}"
echo "============================================"

if [[ "${SELF_DESTRUCTION}" == "true" ]]; then
    echo ""
    echo "⚠️  SELF-DESTRUCTION DETECTED: This agent appears to be running"
    echo "    on the VM you are about to delete. Deleting it will terminate"
    echo "    this session and any unsaved work will be lost."
    echo ""
fi

if [[ -n "${SERVICES_OUTPUT}" ]]; then
    echo ""
    echo "RUNNING SERVICES (systemd):"
    echo "${SERVICES_OUTPUT}" | awk '{printf "  %-40s %s\n", $1, $4}' | head -50
    SERVICE_COUNT=$(echo "${SERVICES_OUTPUT}" | wc -l | tr -d ' ')
    echo "  (${SERVICE_COUNT} services running)"
else
    echo ""
    echo "RUNNING SERVICES: Unable to retrieve (SSH failed or VM unreachable)"
fi

if [[ -n "${DOCKER_OUTPUT}" ]]; then
    echo ""
    echo "RUNNING DOCKER CONTAINERS:"
    echo "${DOCKER_OUTPUT}" | while IFS=$'\t' read -r name image status; do
        [[ -n "${name}" ]] && printf "  %-30s %-30s %s\n" "${name}" "${image}" "${status}"
    done
    CONTAINER_COUNT=$(echo "${DOCKER_OUTPUT}" | grep -c . 2>/dev/null || echo "0")
    echo "  (${CONTAINER_COUNT} containers running)"
fi

echo ""
echo "These services will be lost when the VM is deleted."
echo "============================================"
