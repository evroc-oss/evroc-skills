---
name: evroc-networking
description: "Use when the user wants to create, list, inspect, update, or delete evroc networking resources — public IPs, security groups, subnets, or VPCs. Requires the evroc CLI. Do NOT trigger for compute VMs, disks, IAM, storage buckets, load balancers, or Think models."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.0"
  category: networking
allowed-tools: terminal, read_file
---

# evroc-networking

Manage evroc networking resources through the `evroc networking` CLI.
Covers public IPs, security groups, subnets, and VPCs.

These resources are **prerequisites** for compute (VMs need subnets and security
groups), load balancers (need public IPs), and Rancher deployments (need public IPs
and security groups). Create networking resources first, then reference them in
other skills.

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, or delete an evroc public IP
- User wants to create or manage security groups and their rules
- User wants to create or manage subnets
- User wants to create or manage VPCs
- User mentions "evroc" with "public IP", "security group", "subnet", "VPC", or "network"

**Do NOT use for:** compute VMs, IAM, storage (buckets), load balancers,
or Think models.

## Prerequisites

Run the auth check first:

```bash
bash scripts/check-auth.sh
```

If it fails:

```bash
evroc login
```

## Public IPs

Public IPs are required for load balancers, Rancher server nodes, and any VM that
needs inbound internet access.

### List public IPs

```bash
evroc networking publicip list

evroc networking publicip list -o yaml
```

### Get public IP details

```bash
evroc networking publicip get <ip-name> -o yaml
```

### Create a public IP

```bash
evroc networking publicip create my-ip
```

**Completion criterion:** `evroc networking publicip get my-ip` returns the IP
with an assigned address.

### Delete a public IP

```bash
evroc networking publicip delete <ip-name> -f
```

**Completion criterion:** `evroc networking publicip get <ip-name>` returns
`not found`.

## Security Groups

Security groups are stateful firewalls attached to VM network interfaces. The default
deny model means any traffic not explicitly allowed is blocked.

### List security groups

```bash
evroc networking securitygroup list

evroc networking securitygroup list -o yaml
```

### Get security group details

```bash
evroc networking securitygroup get <sg-name> -o yaml
```

### Create a security group

```bash
evroc networking securitygroup create my-sg
```

**Completion criterion:** `evroc networking securitygroup get my-sg` returns the group.

### Add a rule

```bash
evroc networking securitygroup addrule my-sg \
  --name=allow-ssh \
  --direction=Ingress \
  --protocol=TCP \
  --port=22 \
  --remote-ip=0.0.0.0/0
```

### Remove a rule

```bash
evroc networking securitygroup removerule my-sg \
  --name=allow-ssh
```

### Delete a security group

```bash
evroc networking securitygroup delete <sg-name> -f
```

**Completion criterion:** `evroc networking securitygroup get <sg-name>` returns
`not found`.

## Subnets

Subnets are scoped to a region-zone pair. The default subnet follows the pattern
`default-<region>-<zone>` (e.g. `default-se-sto-a`).

### List subnets

```bash
evroc networking subnet list

evroc networking subnet list -o yaml
```

### Get subnet details

```bash
evroc networking subnet get <subnet-name> -o yaml
```

### Create a subnet

```bash
evroc networking subnet create my-subnet \
  --zone=a \
  --cidr=10.0.1.0/24
```

### Delete a subnet

```bash
evroc networking subnet delete <subnet-name> -f
```

**Completion criterion:** `evroc networking subnet get <subnet-name>` returns
`not found`.

## VPCs

VPCs are isolated network containers. A VPC can span multiple regions. Subnets live
inside VPCs.

### List VPCs

```bash
evroc networking vpc list

evroc networking vpc list -o yaml
```

### Get VPC details

```bash
evroc networking vpc get <vpc-name> -o yaml
```

### Create a VPC

```bash
evroc networking vpc create my-vpc \
  --cidr=10.0.0.0/16
```

### Delete a VPC

```bash
evroc networking vpc delete <vpc-name> -f
```

**Completion criterion:** `evroc networking vpc get <vpc-name>` returns `not found`.

## Quota Check Helper

Before creating resources that need public IPs, verify quota:

```bash
bash scripts/check-public-ip-quota.sh <needed>
```

Returns the number of available public IPs vs the 3-IP account quota. Exits
non-zero if insufficient.

## Pitfalls

- **Default-deny model**: evroc security groups block all traffic not explicitly
  allowed. If a VM can't be reached, check the security group rules (not just the VM).
- **Subnet naming**: Default subnets follow `default-<region>-<zone>` (e.g.
  `default-se-sto-a`). Custom subnets follow the same zone-scoping rules.
- **Security group scope**: Security groups are project-scoped. A security group in
  one project cannot be attached to a VM in another project.
- **Rule direction**: `Ingress` = inbound to the VM. `Egress` = outbound from the VM.
  The default-deny applies to both directions independently.
- **Public IP quota**: evroc accounts have a 3-IP quota. Run
  `evroc networking publicip list` to check usage. Free unused IPs before
  creating new ones.
- **Delete order**: Delete VMs and load balancers before deleting the security
  groups, public IPs, and subnets they reference. Resources with active references
  cannot be deleted.
- **Name rules**: Max 63 chars, lowercase alphanumeric with hyphens, starting/ending
  alphanumeric.
- **CLI aliases**: `sg` for `securitygroup`, `lb` for `loadbalancer`, `ls` for `list`,
  `rm`/`del` for `delete`, `new` for `create`.
