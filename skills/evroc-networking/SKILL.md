---
name: evroc-networking
description: "Use when the user wants to create, list, inspect, update, or delete evroc networking resources — public IPv4 and IPv6 addresses, security groups (dual-stack), subnets, or VPCs. Requires the evroc CLI. Do NOT trigger for compute VMs, disks, IAM, storage buckets, load balancers, or Think models."
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

Ensure the evroc CLI is installed:

```bash
bash scripts/check-cli.sh
```

Then authenticate:

```bash
bash scripts/check-auth.sh
```

If it fails:

```bash
evroc login
```

## Public IPs

Public IPv4 addresses are a scarce resource. evroc accounts have a 3-address
quota. Elastic IPv4s are required for load balancers, Rancher server nodes,
and any VM that needs fixed inbound internet access over IPv4.

IPv6 is end-to-end by design: each VM in an IPv6-enabled subnet receives a
globally routable address without NAT, because every IPv6 subnet allocation is
a /64 and individual addresses are globally unique by default (see RFC 4291,
Section 2.5.1 on Global Unicast addresses). This eliminates the need for
elastic IP allocation, NAT gateways, or port forwarding that IPv4 requires.

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

**IPv4 / IPv6 side-by-side:**

```bash
# IPv4 rule
evroc networking securitygroup addrule my-sg \
  --name=allow-ssh \
  --direction=Ingress \
  --protocol=TCP \
  --port=22 \
  --remote-ip-or-cidr=0.0.0.0/0

# IPv6 rule
evroc networking securitygroup addrule my-sg \
  --name=allow-ssh-v6 \
  --direction=Ingress \
  --protocol=TCP \
  --port=22 \
  --remote-ip-or-cidr=::/0
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
# IPv4 subnet
evroc networking subnet create my-subnet-v4 \
  --zone=a \
  --cidr=10.0.1.0/24
```

**IPv6 example side-by-side:**
- **IPv4:** `--cidr=10.0.1.0/24` (RFC1918 private range, 256 addresses)  
- **IPv6:** `--cidr=fd00:10:1::/64` (ULA range, 18 quintillion addresses)

```bash
# IPv4 subnet
evroc networking subnet create my-subnet-v4 \
  --zone=a \
  --cidr=10.0.1.0/24

# IPv6 subnet
evroc networking subnet create my-subnet-v6 \
  --zone=a \
  --cidr=fd00:10:1::/64
```

### Create a dual-stack subnet

For a subnet that supports both IPv4 (for legacy reachability) and IPv6
(end-to-end connectivity), assign both CIDRs:

```bash
evroc networking subnet create my-subnet-dual \
  --zone=a \
  --cidr=10.0.1.0/24 \
  --cidr-v6=fd00:10:1::/64
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
# IPv4 VPC
evroc networking vpc create my-vpc-v4 \
  --cidr=10.0.0.0/16
```

**IPv6 example side-by-side:**
- **IPv4:** `--cidr=10.0.0.0/16` (RFC1918, ~65k addresses across all subnets)  
- **IPv6:** `--cidr=fd00:10::/56` (ULA, /64 per subnet, auto-assigned to VMs)

```bash
# IPv4 VPC
evroc networking vpc create my-vpc-v4 \
  --cidr=10.0.0.0/16

# IPv6 VPC
evroc networking vpc create my-vpc-v6 \
  --cidr=fd00:10::/56
```

### Create a dual-stack VPC

For a VPC that supports both IP families, provide both CIDRs at creation:

```bash
evroc networking vpc create my-vpc-dual \
  --cidr=10.0.0.0/16 \
  --cidr-v6=fd00:10::/56
```

### Delete a VPC

```bash
evroc networking vpc delete <vpc-name> -f
```

**Completion criterion:** `evroc networking vpc get <vpc-name>` returns `not found`.

## Quota Check Helper (IPv4 Elastic IPs)

Before creating resources that need public IPv4 addresses (load balancers, VMs
with fixed IPv4), verify remaining quota:

```bash
bash scripts/check-public-ip-quota.sh <needed>
```

Returns the number of available elastic IPv4 addresses vs the 3-address
account quota. Exits non-zero if insufficient.

**Not needed for IPv6.** Every VM in an IPv6-enabled subnet receives a
public address automatically without quota tracking.

## Pitfalls

- **Default-deny model**: evroc security groups block all traffic not explicitly
  allowed. If a VM can't be reached, check the security group rules (not just the VM).
- **Subnet naming**: Default subnets follow `default-<region>-<zone>` (e.g.
  `default-se-sto-a`). Custom subnets follow the same zone-scoping rules.
- **Security group scope**: Security groups are project-scoped. A security group in
  one project cannot be attached to a VM in another project.
- **Rule direction**: `Ingress` = inbound to the VM. `Egress` = outbound from the VM.
  The default-deny applies to both directions independently.
- **IPv4 quota**: evroc accounts have a 3-address elastic IPv4 quota. IPv6 has no per-address quota. Run
  `evroc networking publicip list` to check IPv4 usage. Free unused IPv4 addresses before
  creating new ones.
- **IPv6 security groups require ICMPv6**: In dual-stack or IPv6-only subnets, security group rules
  must explicitly allow ICMPv6 traffic. IPv6 Neighbor Discovery (N/D), Router Solicitation (RS),
  and Router Advertisement (RA) all use ICMPv6. Blocking these prevents address configuration and
  basic Layer 3 reachability. Add a rule for `ICMPv6` on both Ingress and Egress directions.
- **Delete order**: Delete VMs and load balancers before deleting the security
  groups, public IPs, and subnets they reference. Resources with active references
  cannot be deleted.
- **Name rules**: Max 63 chars, lowercase alphanumeric with hyphens, starting/ending
  alphanumeric.
- **CLI aliases**: `sg` for `securitygroup`, `lb` for `loadbalancer`, `ls` for `list`,
  `rm`/`del` for `delete`, `new` for `create`.
