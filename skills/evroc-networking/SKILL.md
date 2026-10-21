---
name: evroc-networking
description: "Use when the user wants to create, list, inspect, update, or delete evroc networking resources — public IPv4 and IPv6 addresses, security groups (dual-stack), subnets, or VPCs. Requires the evroc CLI. Do NOT trigger for compute VMs, disks, IAM, storage buckets, load balancers, or Think models."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.2"
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

HALT: Before running ANY `evroc networking publicip delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete your Public IP '<ip-name>' and cannot be undone."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<ip-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc networking publicip delete <ip-name> --force
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
evroc networking securitygroup create my-sg \
  --vpc=default-se-sto
```

**Flags:**
- `--vpc <vpc-name>`: VPC the security group belongs to (e.g. `default-se-sto`).

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

**Flags:**
- `--port <int>`: Single port for the rule (used as both start and end port).
- `--end-port <int>`: End of a port range; use with `--port` (as start) to open a range (e.g. `--port=8000 --end-port=8100`).
- `--security-group <sg-name>`: Target security group by name (alternative to passing it as a positional argument).
- `--subnet <subnet-name>`: Restrict the rule to traffic from a specific subnet instead of a CIDR.

### Remove a rule

```bash
evroc networking securitygroup removerule my-sg \
  --name=allow-ssh
```

### Delete a security group

HALT: Before running ANY `evroc networking securitygroup delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete your Security Group '<sg-name>' and cannot be
undone."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<sg-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc networking securitygroup delete <sg-name> --force
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
# Dual-stack subnet (IPv4 + IPv6)
evroc networking subnet create my-subnet-dual \
  --zone=a \
  --ipv4-cidr-block=10.0.1.0/24 \
  --stack-type=dual-stack \
  --vpc=default-se-sto
```

**CIDR notes:**
- **IPv4:** `--ipv4-cidr-block=10.0.1.0/24` (RFC1918 private range, 256 addresses)
- **IPv6:** IPv6 addressing is automatic in dual-stack mode; no separate IPv6 CIDR flag is needed.
- **VPC:** `--vpc=default-se-sto` attaches the subnet to the default VPC for the `se-sto` region.

### Delete a subnet

HALT: Before running ANY `evroc networking subnet delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete your Subnet '<subnet-name>' and cannot be
undone."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<subnet-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc networking subnet delete <subnet-name> --force
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
# Dual-stack VPC (IPv4 + IPv6)
evroc networking vpc create my-vpc-dual \
  --ipv4-cidr-block=10.0.0.0/16 \
  --stack-type=dual-stack
```

**CIDR notes:**
- **IPv4:** `--ipv4-cidr-block=10.0.0.0/16` (RFC1918, ~65k addresses across all subnets)
- **IPv6:** IPv6 addressing is automatic in dual-stack mode; no separate IPv6 CIDR flag is needed.

### Delete a VPC

HALT: Before running ANY `evroc networking vpc delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete your VPC '<vpc-name>' and cannot be undone."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<vpc-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc networking vpc delete <vpc-name> --force
```

**Completion criterion:** `evroc networking vpc get <vpc-name>` returns `not found`.

## Quota Check Helper (Public IPs)

Pre-flight check (before creating resources that need public IPv4 addresses —
load balancers, VMs with fixed IPv4, Rancher deployments):

```bash
bash scripts/check-public-ip-quota.sh <needed>
bash scripts/check-quota.sh publicips <needed>   # same info, newer script
```

Both read the REAL public IP quota from the API (`evroc quotas orgquotas get`),
not a hardcoded limit, so they are correct even for organizations with raised
quotas. Exits non-zero if insufficient.

For the post-failure path (a create that already returned 403 `InsufficientQuota`),
see [Quota errors (InsufficientQuota)](#quota-errors-insufficientquota) below.

**Not needed for IPv6.** Every VM in an IPv6-enabled subnet receives a
public address automatically without quota tracking.

## Quota errors (InsufficientQuota)

Public IP creation fails with HTTP 403 when the organization's public IP quota is exhausted. The API response contains `reason: "InsufficientQuota"` and the text `not enough quota to perform request`.

Committed quotas are org-wide: current usage in ANY project of the organization counts against the same limit. A 403 from an empty project usually means another project consumed the quota.

HALT: When a `create` command fails with HTTP 403 and a body containing
"InsufficientQuota" (or the text "not enough quota to perform request"), you MUST:

1. Run: `bash scripts/check-quota.sh publicips` (or `evroc quotas orgquotas get`)
2. Report to the user VERBATIM: current public IP usage and limit — e.g.
   "Public IPs: 70/70 used — at limit"
3. State: "To request a quota increase, contact support@evroc.com"
4. Do NOT retry the command until the user decides (free unused IPs with
   `evroc networking publicip delete <id>`, or contact support). A silence or
   ambiguous response is NOT confirmation to retry.

## Pitfalls

- **Default-deny model**: evroc security groups block all traffic not explicitly
  allowed. If a VM can't be reached, check the security group rules (not just the VM).
- **Subnet naming**: Default subnets follow `default-<region>-<zone>` (e.g.
  `default-se-sto-a`). Custom subnets follow the same zone-scoping rules.
- **Security group scope**: Security groups are project-scoped. A security group in
  one project cannot be attached to a VM in another project.
- **Rule direction**: `Ingress` = inbound to the VM. `Egress` = outbound from the VM.
  The default-deny applies to both directions independently.
- **IPv4 quota**: The public IPv4 quota is org-level (commonly 3 by default, raisable). IPv6 has no per-address
  quota. Check REAL usage and limit with `evroc quotas orgquotas get` or
  `bash scripts/check-public-ip-quota.sh`. Free unused IPv4 addresses before
  creating new ones. To request a quota increase, contact support@evroc.com.
- **IPv6 security groups require ICMP**: In dual-stack or IPv6-only subnets, security group rules
  must explicitly allow ICMP traffic. The CLI `--protocol ICMP` value covers both ICMPv4 and
  ICMPv6 depending on the CIDR family. IPv6 Neighbor Discovery (N/D), Router Solicitation (RS),
  and Router Advertisement (RA) all use ICMPv6. Blocking this prevents address configuration and
  basic Layer 3 reachability. Add a rule for `ICMP` on both Ingress and Egress directions.
- **Delete order**: Delete VMs and load balancers before deleting the security
  groups, public IPs, and subnets they reference. Resources with active references
  cannot be deleted.
- **Name rules**: Max 63 chars, lowercase alphanumeric with hyphens, starting/ending
  alphanumeric.
- **Labeling**: All networking resources (public IPs, security groups, subnets, VPCs)
  support the `label` subcommand for adding/removing labels:
  `evroc networking <resource> label <name> --add key=value --remove key`.
  See [`references/cli-reference.md`](references/cli-reference.md) for details.
- **CLI aliases**: `sg` for `securitygroup`, `vpc` for `virtualprivatecloud`, `ls` for `list`,
  `rm`/`del` for `delete`, `new` for `create`.
