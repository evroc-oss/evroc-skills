---
name: evroc-networking
description: "Use when the user wants to create, list, inspect, or delete evroc networking resources — VPCs, subnets, security groups, and public IPs. Requires the evroc CLI. Do NOT trigger for compute VMs, IAM, storage, load balancers, or Think models."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.0"
  category: networking
allowed-tools: terminal, read_file
---

# evroc-networking

Manage evroc networking resources through the `evroc networking` CLI. Covers
VPCs, subnets, security groups, and public IPs.

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, or delete a VPC on evroc
- User wants to create or manage subnets on evroc
- User wants to create or manage security groups and their rules on evroc
- User wants to create, list, or delete public IPs on evroc
- User mentions "evroc" with "VPC", "subnet", "security group", "firewall rule", "public IP", or "networking"

**Do NOT use for:** compute VMs, IAM, storage (buckets), load balancers, or Think models.

## Prerequisites

Run the auth check first:

```bash
bash scripts/check-auth.sh
```

If it fails:

```bash
evroc login
```

## VPCs

### List VPCs

```bash
# Names only
evroc networking vpc list

# YAML output with full details
evroc networking vpc list -o yaml

# Filter by label
evroc networking vpc list -l "environment=production"
```

### Get VPC details

```bash
evroc networking vpc get <vpc-name> -o yaml
```

### Create a VPC

Requires an IPv4 CIDR block using RFC 1918 private address space
(e.g. `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`).

```bash
evroc networking vpc create my-vpc \
  --ipv4-cidr-block=10.0.0.0/8 \
  --stack-type=dual-stack
```

### Delete a VPC

```bash
evroc networking vpc delete my-vpc --force
```

**Completion criterion:** `evroc networking vpc get <vpc-name>` returns `not found`.

## Subnets

### List subnets

```bash
evroc networking subnet list

evroc networking subnet list -o yaml

evroc networking subnet list -l "team=backend"
```

### Get subnet details

```bash
evroc networking subnet get <subnet-name> -o yaml
```

### Create a subnet

Requires a VPC and a zone. The default subnet naming pattern is
`default-<region>-<zone>` (e.g. `default-se-sto-a`, `default-se-sto-b`).

```bash
evroc networking subnet create default-se-sto-a \
  --ipv4-cidr-block=10.0.0.0/24 \
  --stack-type=dual-stack \
  --vpc=my-vpc \
  --zone=a
```

### Delete a subnet

```bash
evroc networking subnet delete my-subnet --force
```

**Completion criterion:** `evroc networking subnet get <subnet-name>` returns `not found`.

## Security Groups

VMs require security groups for network access. Without explicitly assigned
security groups, the VM's firewall will drop all traffic.

### List security groups

```bash
evroc networking securitygroup list
```

### Get security group details

```bash
evroc networking securitygroup get <sg-name> -o yaml
```

### Create a security group

Security groups can reference a VPC:

```bash
evroc networking securitygroup create my-sg --vpc=my-vpc
```

### Add a rule to a security group

Security group rules have the following parameters:
- **direction**: `Ingress` or `Egress`
- **protocol**: `All`, `TCP`, `UDP`, or `ICMP`
- **port**: Single port number. Use `0` for all ports.
- **end-port**: End of port range (optional, for port ranges)

Rule sources are mutually exclusive — use exactly one of:
- `--remote-ip-or-cidr` — an IP address or CIDR block (e.g. `0.0.0.0/0`, `10.0.0.0/24`)
- `--security-group` — reference another security group by name
- `--subnet` — reference a subnet by name

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

# Allow all traffic from within a subnet
evroc networking securitygroup addrule my-sg \
  --name=allow-intra-subnet \
  --direction=Ingress \
  --subnet=default-se-sto-a \
  --port=0 \
  --protocol=All

# Allow traffic from another security group
evroc networking securitygroup addrule my-sg \
  --name=allow-from-other-sg \
  --direction=Ingress \
  --security-group=other-sg \
  --port=0 \
  --protocol=All
```

> **Note:** IPv4 and IPv6 rules are separate — create one rule per protocol if you need both.

### Remove a rule from a security group

```bash
evroc networking securitygroup removerule my-sg \
  --name=allow-ssh-ipv4 \
  --direction=Ingress \
  --remote-ip-or-cidr=0.0.0.0/0 \
  --port=22 \
  --protocol=TCP
```

### Delete a security group

```bash
evroc networking securitygroup delete my-sg --force
```

**Completion criterion:** `evroc networking securitygroup get <sg-name>` returns `not found`.

## Public IPs

Public IPs provide external internet connectivity for evroc resources. Each
account has a quota of **3 public IPs** — check existing IPs before creating
new ones.

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
evroc networking publicip create my-public-ip
```

### Delete a public IP

```bash
evroc networking publicip delete my-public-ip --force
```

**Completion criterion:** `evroc networking publicip get <ip-name>` returns `not found`.

## Pitfalls

- **VPC requires RFC 1918 CIDR**: The `--ipv4-cidr-block` flag must use a private
  address range from RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`).
  Using a public range will cause creation to fail.
- **Subnet naming pattern**: Default subnets follow `default-<region>-<zone>`
  (e.g. `default-se-sto-a`). The zone in the subnet name must match the `--zone`
  flag. When a user asks for a VM in zone b, the subnet is `default-se-sto-b`,
  not `default-se-sto-a`.
- **Subnets require VPC and zone**: Both `--vpc` and `--zone` are required when
  creating a subnet. A subnet cannot exist without a parent VPC.
- **Security group rule sources are mutually exclusive**: Use exactly one of
  `--remote-ip-or-cidr`, `--security-group`, or `--subnet` per rule. Combining
  multiple source flags in a single rule is an error.
- **Port 0 means all ports**: When `--port=0` is specified, the rule applies to
  all ports. Use this with `--protocol=All` for unrestricted access (typically
  only for intra-VPC or intra-subnet traffic).
- **Public IP quota**: Each account is limited to 3 public IPs. Check existing
  IPs with `evroc networking publicip list` before creating new ones. If the
  quota is exhausted, creation will fail — delete unused IPs first.
- **IPv4 and IPv6 are separate rules**: A rule for `0.0.0.0/0` only covers IPv4.
  To allow IPv6 traffic, create a separate rule with `::/0` as the CIDR.
- **Security groups can reference a VPC**: When creating a security group, the
  `--vpc` flag associates it with a specific VPC. This is optional but
  recommended for organized network isolation.
- **CLI aliases**: `net` for `networking`, `sg` for `securitygroup`,
  `vpc` for `virtualprivatecloud`, `ip` for `publicip`.
- **Output formats**: `-o yaml` (default for `get`), `-o json`, `-o list` (default
  for `list`, shows names only). Use `yaml` or `json` when you need full resource
  details.
- **Label selectors**: Kubernetes-style syntax: `key=value`,
  `key in (val1,val2)`, `!key`. Works with user labels and system labels.
- **Name rules**: Max 63 chars, lowercase alphanumeric with hyphens,
  starting/ending alphanumeric.
- **Delete order**: Delete subnets before their parent VPC. Delete security
  group rules before deleting the security group if needed (or use `--force`).
- **Checking readiness — use JSON + jq**: The `status:` key appears at both the
  top level and nested under `conditions[]` in the YAML/JSON output. Grepping
  for `status:` matches the wrong field. Always use:
  `evroc networking <resource> get <name> -o json | jq -r '.status.conditions[] | select(.type=="Ready") | .status'`
  to check readiness.
