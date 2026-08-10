---
name: evroc-compute
description: "Manage evroc compute resources: virtual machines, disks, snapshots, and placement groups via the evroc CLI. Use when the user wants to create, list, inspect, update, or delete VMs and disks on evroc cloud."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.0"
  category: infrastructure
allowed-tools: terminal
---

# evroc-compute

Manage evroc compute resources through the `evroc compute` CLI. Covers virtual machines, disks, snapshots, and placement groups.

For full CLI flag reference, read [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, update, or delete a VM on evroc
- User wants to create or manage disks on evroc
- User wants to take or manage disk snapshots
- User wants to create placement groups for VM scheduling
- User mentions "evroc" with "VM", "instance", "disk", or "compute"

## Prerequisites

The evroc CLI must be installed and authenticated:

```bash
evroc login --domain evroc.com --organization evroc
```

Verify auth:

```bash
cat ~/.evroc/config.yaml
```

## Virtual Machines

### List VMs

```bash
# Simple list of VM names
evroc compute vm list

# YAML output with full details
evroc compute vm list -o yaml

# JSON output
evroc compute vm list -o json

# Filter by label
evroc compute vm list -l "team in (frontend,backend)"
```

### Get VM details

```bash
evroc compute vm get <vm-name>

# JSON output
evroc compute vm get <vm-name> -o json
```

### Create a VM

A VM requires a boot disk, a flavor (compute profile), a subnet, and a zone. Create the disk first, then the VM:

```bash
# 1. Create a boot disk from an Ubuntu image
evroc compute disk create my-boot-disk \
  --image=ubuntu-minimal-24.04.1 \
  --size-amount=50 \
  --size-unit=GB \
  --zone=a

# 2. Create the VM
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

**Completion criterion:** `evroc compute vm get <vm-name>` returns the VM with status showing it exists and is running.

### Create a VM with cloud-init

Pass user-data for automated provisioning:

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
# Attach an additional disk (append mode keeps existing disks)
evroc compute vm update my-vm --append --disk=extra-disk --boot-from=false

# Attach a security group
evroc compute vm update my-vm --append --security-group=additional-sg

# Stop a VM
evroc compute vm update my-vm --running=false

# Start a VM
evroc compute vm update my-vm --running=true

# Assign a public IP
evroc compute vm update my-vm --public-ip=my-public-ip-name
```

### Delete a VM

```bash
evroc compute vm delete my-vm

# Skip confirmation
evroc compute vm delete my-vm --force
```

**Completion criterion:** `evroc compute vm get <vm-name>` returns an error (VM not found).

## Disks

### List disks

```bash
evroc compute disk list

# With details
evroc compute disk list -o yaml

# Filter by label
evroc compute disk list -l "environment=production"
```

### Get disk details

```bash
evroc compute disk get <disk-name>
```

### Create a disk

From an image:

```bash
evroc compute disk create my-disk \
  --image=ubuntu-minimal-24.04.1 \
  --size-amount=100 \
  --size-unit=GB \
  --zone=a
```

From a snapshot:

```bash
evroc compute disk create my-disk \
  --snapshot=my-snapshot \
  --zone=a
```

### Delete a disk

```bash
evroc compute disk delete <disk-name>
```

## Snapshots

### Create a snapshot from a disk

```bash
evroc compute snapshot create my-snapshot --disk-ref=my-disk
```

### List snapshots

```bash
evroc compute snapshot list
```

### Get snapshot details

```bash
evroc compute snapshot get <snapshot-name>
```

### Delete a snapshot

```bash
evroc compute snapshot delete <snapshot-name>
```

## Placement Groups

Placement groups control VM scheduling — e.g. spread VMs across physical hosts for resilience.

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

- **Disk before VM**: A VM requires a pre-existing boot disk. Create the disk first, then reference it by name in `--disk`.
- **Boot-from flag**: When attaching a disk, `--boot-from=true` marks the boot disk. Additional disks use `--boot-from=false`. Every disk attachment must specify this flag.
- **Subnet naming**: Subnets are region-zone scoped — the default is `default-<region>-<zone>` (e.g. `default-se-sto-a`). The zone in the subnet name must match the `--zone` flag.
- **Flavor format**: Compute profiles use `<series>.<size>` — e.g. `a1a.m`, `c1a.l`, `m1a.xl`. Series include `a1a` (general), `c1a` (compute-optimized), `m1a` (memory-optimized).
- **CLI aliases**: `vm` is an alias for `virtualmachine`, `ls` for `list`, `rm`/`del` for `delete`, `new` for `create`. Both forms work.
- **Output formats**: `-o yaml` (default for get), `-o json`, `-o list` (default for list, shows just names). Use `yaml` or `json` when you need full resource details.
- **Label selectors**: Use Kubernetes-style syntax — `key=value`, `key in (val1,val2)`, `!key`. Works with both user labels and system labels.
- **Delete order**: Delete VMs before deleting their attached disks. Disks must be detached (VM deleted) before they can be removed.
