---
name: evroc-compute
description: "Use when the user wants to create, list, inspect, update, or delete evroc VMs, disks, snapshots, or placement groups. Requires the evroc CLI. Do NOT trigger for IAM, networking, storage buckets, load balancers, or Think model operations."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.1"
  category: infrastructure
allowed-tools: terminal, read_file
---

# evroc-compute

Manage evroc compute resources through the `evroc compute` CLI. Covers VMs, disks,
snapshots, and placement groups.

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, update, or delete a VM on evroc
- User wants to create or manage disks on evroc
- User wants to take or manage disk snapshots
- User wants to create placement groups for VM scheduling
- User mentions "evroc" with "VM", "instance", "disk", "snapshot", or "compute"

**Do NOT use for:** IAM, networking, storage (buckets), load balancers, or Think models.

## Prerequisites

Run the auth check first:

```bash
bash scripts/check-auth.sh
```

If it fails, authenticate:

```bash
evroc login
```

## Virtual Machines

### List VMs

```bash
# Names only
evroc compute vm list

# YAML output with full details
evroc compute vm list -o yaml

# Filter by label
evroc compute vm list -l "team in (frontend,backend)"
```

### Get VM details

```bash
evroc compute vm get <vm-name> -o yaml
```

### Create a VM

Requires: a pre-existing boot disk, a flavor, a subnet, and a zone.

**Before creating the boot disk, ask the user which OS image they want.**
Available images are listed in [`references/cli-reference.md`](references/cli-reference.md#available-disk-images)
(e.g. `ubuntu-minimal.24-04.1`, `ubuntu.24-04.1`, `rocky.9-6.1`). Do not guess —
present the options and confirm the user's choice.

```bash
# 1. Create boot disk (ask user which image — see references/cli-reference.md)
evroc compute disk create my-boot-disk \
  --image=<image-name> \
  --size-amount=50 \
  --size-unit=GB \
  --zone=a

# 2. Create VM
evroc compute vm create my-vm \
  --vm-virtual-resources-ref=a1a.m \
  --disk=my-boot-disk \
  --boot-from=true \
  --subnet=default-se-sto-a \
  --security-group=my-sg \
  --ssh-authorized-key="ssh-ed25519 AAAA... user@example.com" \
  --zone=a \
  --running=true
```

**Completion criterion:** The VM has a `Ready` condition with `status: "True"` **and**
`virtualMachineStatus: "Running"`. The VM goes through several conditions before Ready
(`SecurityGroupsReady`, `NetworkingReady`, `VMIsRunning`, `Ready`), so checking just
`reason:` or grepping `status:` returns intermediate states like `SecurityGroupsReady`.

Poll for VM readiness:

```bash
# Returns "True" when the VM is fully Ready
evroc compute vm get <vm-name> -o json | jq -r '.status.conditions[] | select(.type=="Ready") | .status'

# Returns "Running" when the VM is up
evroc compute vm get <vm-name> -o json | jq -r '.status.virtualMachineStatus'
```

Do NOT grep for `status:` or `reason:` in YAML — there are multiple condition entries
and grep matches the first one (e.g. `SecurityGroupsReady`), not the overall Ready state.

### Create a VM with cloud-init

```bash
evroc compute vm create my-vm \
  --vm-virtual-resources-ref=a1a.m \
  --disk=my-boot-disk \
  --boot-from=true \
  --subnet=default-se-sto-a \
  --zone=a \
  --cloud-init-user-data="#cloud-config
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx"
```

### Update a VM

```bash
# Attach an additional disk
evroc compute vm update my-vm --append --disk=extra-disk --boot-from=false

# Attach a security group
evroc compute vm update my-vm --append --security-group=additional-sg

# Stop / start
evroc compute vm update my-vm --running=false
evroc compute vm update my-vm --running=true

# Assign a public IP
evroc compute vm update my-vm --public-ip=my-public-ip-name
```

## Security Groups

VMs require security groups for network access. Without explicitly assigned
security groups, the VM's firewall will drop all traffic.

### Default security groups

Each project includes four preconfigured security groups:

| Security Group | Allows |
|---|---|
| `default-allow-egress` | All outbound traffic (IPv4 + IPv6). VMs are auto-added unless you specify custom groups. |
| `default-allow-intra-vpc` | All inbound + outbound traffic within the default VPC (inter-VM communication). |
| `default-allow-web-protocols` | HTTP (TCP 80) + HTTPS (TCP 443) from any IP. |
| `default-allow-ssh` | SSH (TCP 22) from any IP. Must be explicitly added. |

### List existing security groups

Before creating a new security group, check what already exists:

```bash
evroc networking securitygroup list
```

### Create a security group

```bash
evroc networking securitygroup create my-sg
```

### Add rules to a security group

```bash
# Allow SSH from anywhere (IPv4)
evroc networking securitygroup addrule my-sg \
  --name=allow-ssh-ipv4 \
  --direction=Ingress \
  --remote-ip-or-cidr=0.0.0.0/0 \
  --port=22 \
  --protocol=TCP

# Allow HTTPS from anywhere (IPv6)
evroc networking securitygroup addrule my-sg \
  --name=allow-https-ipv6 \
  --direction=Ingress \
  --remote-ip-or-cidr=::/0 \
  --port=443 \
  --protocol=TCP
```

> **Note:** IPv4 and IPv6 rules are separate — create one rule per protocol if you need both.

### Attach a security group to a VM

```bash
# Append (keeps existing groups)
evroc compute vm update my-vm --append --security-group=my-sg

# Replace all security groups (must specify ALL groups the VM should have)
evroc compute vm update my-vm \
  --security-group=default-allow-egress \
  --security-group=my-sg
```

> **Warning:** Without `--append`, the update replaces all existing security groups. You must specify the complete list.

### Pre-flight checklist before VM creation

Before creating a VM, verify or create these prerequisites:

1. **Boot disk** — create and wait for `Ready` condition (see [Disks](#disks))
2. **Security group** — either use a default (e.g. `default-allow-ssh`) or create one with
   `evroc networking securitygroup create` + `addrule`. If the user needs SSH access,
   ensure a rule allows TCP 22. If they need web traffic, allow 80/443.
3. **Subnet** — use the default `default-<region>-<zone>` or create one
4. **SSH key** — confirm or ask the user for their SSH public key

### Delete a VM

```bash
evroc compute vm delete my-vm -f
```

**Completion criterion:** `evroc compute vm get <vm-name>` returns `not found`.

## Disks

### List disks

```bash
evroc compute disk list

evroc compute disk list -o yaml
evroc compute disk list -l "environment=production"
```

### Get disk details

```bash
evroc compute disk get <disk-name> -o yaml
```

### Create a disk

From an image (ask the user which one — see [`references/cli-reference.md`](references/cli-reference.md#available-disk-images)):

```bash
evroc compute disk create my-disk \
  --image=<image-name> \
  --size-amount=100 \
  --size-unit=GB \
  --zone=a
```

**Completion criterion:** Wait for the disk's `Ready` condition to be `True` before
creating a VM from it. Poll with:

```bash
evroc compute disk get <disk-name> -o json | jq -r '.status.conditions[] | select(.type=="Ready") | .status'
# Returns "True" when ready. Do NOT grep for "status:" in YAML output —
# the top-level status: field and the nested condition status: field both
# match, causing false readings.
```

From a snapshot:

```bash
evroc compute disk create my-disk \
  --snapshot=my-snapshot \
  --zone=a
```

### Delete a disk

```bash
evroc compute disk delete <disk-name> -f
```

**Completion criterion:** `evroc compute disk get <disk-name>` returns `not found`.

## Snapshots

### Create a snapshot

```bash
evroc compute snapshot create my-snapshot --disk-ref=my-disk
```

### List snapshots

```bash
evroc compute snapshot list
```

### Get snapshot details

```bash
evroc compute snapshot get <snapshot-name> -o yaml
```

### Delete a snapshot

```bash
evroc compute snapshot delete <snapshot-name> -f
```

## Placement Groups

### Create a placement group

```bash
evroc compute placementgroup create my-pg \
  --strategy-type=spread \
  --zone=a
```

### List placement groups

```bash
evroc compute placementgroup list
```

### Assign a VM to a placement group

```bash
evroc compute vm create my-vm \
  --vm-virtual-resources-ref=a1a.m \
  --disk=my-boot-disk \
  --boot-from=true \
  --subnet=default-se-sto-a \
  --placement-group=my-pg \
  --zone=a
```

### Delete a placement group

```bash
evroc compute placementgroup delete my-pg
```

## Pitfalls

- **Disk images — ask, don't guess**: There is no `disk image list` CLI command. Always
  present the available images from [`references/cli-reference.md`](references/cli-reference.md#available-disk-images)
  and let the user choose. Image names use format `<distro>.<version>.1` (dot before version,
  hyphen within). e.g. `ubuntu-minimal.24-04.1`, not `ubuntu-minimal-24.04.1` — wrong
  separators silently create a disk that never becomes Ready (`DiskImageInvalid`).
- **Checking readiness — use JSON + jq, not YAML grep**: The `status:` key appears at both
  the top level and nested under `conditions[]` in the YAML/JSON output. Grepping for
  `status:` matches the wrong field and returns the condition's status (`"True"`) instead
  of the condition's type (`"Ready"`). Always use:
  `evroc compute <resource> get <name> -o json | jq -r '.status.conditions[] | select(.type=="Ready") | .status'`
  to check readiness. For VM running state, use `.status.virtualMachineStatus`.
- **Wait for disk Ready before VM create**: A disk that is not yet Ready will cause VM
  creation to fail with "disk is not ready". Always poll the disk's Ready condition first.
- **Security groups — check or create before VM creation**: Without explicitly assigned
  security groups, the VM's firewall drops all traffic. Before creating a VM, check
  existing groups with `evroc networking securitygroup list`. If the user needs SSH access,
  ensure `default-allow-ssh` is attached or create a custom group with a TCP 22 ingress
  rule. If the user needs web traffic, ensure 80/443 are allowed. The VM's
  `SecurityGroupsReady` condition will show `True` once groups are resolved.
- **Disk before VM**: Always create the boot disk first. The VM references it by name.
- **Boot-from flag**: Every disk attachment must specify `--boot-from` (`true` for boot,
  `false` for data).
- **Subnet naming**: Pattern is `default-<region>-<zone>`. The zone in the subnet name must
  match `--zone`.
- **Flavor format**: `<series>.<size>` — e.g. `a1a.m`, `c1a.l`. Series: `a1a` (general),
  `c1a` (compute-optimized), `m1a` (memory-optimized).
- **Delete order**: Delete VMs before their attached disks. Disks must be detached before
  deletion.
- **Output formats**: `-o yaml` (default for `get`), `-o json`, `-o list` (default for `list`,
  shows names only). Use `yaml` or `json` when you need full resource details.
- **Label selectors**: Kubernetes-style syntax: `key=value`, `key in (val1,val2)`, `!key`.
  Works with user labels and system labels.
- **Name rules**: Max 63 chars, lowercase alphanumeric with hyphens, starting/ending
  alphanumeric.
