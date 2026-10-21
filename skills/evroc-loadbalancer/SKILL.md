---
name: evroc-loadbalancer
description: "Use when the user wants to create, configure, or delete evroc load balancers, backend pools, backend services, health checks, L4 routes, or listeners. Requires the evroc CLI and a pre-existing public IP (managed via evroc-networking). Do NOT trigger for compute VMs, IAM, storage buckets, networking resources, or Think models."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux. This is a beta service — syntax may change between releases. First terraform init downloads the evroc provider from registry.terraform.io (~20 MB)."
metadata:
  author: evroc
  version: "1.3"
  category: networking
allowed-tools: terminal, read_file
---

# evroc-loadbalancer

Manage evroc load balancers through the `evroc loadbalancer` CLI.
Covers backend pools, backend services, health checks, L4 routes, and listeners.

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create or manage a load balancer on evroc
- User wants to configure backend pools with VM backends
- User wants to set up health checks (HTTP or TCP) for backend services
- User wants to configure L4 routes and listeners for traffic distribution
- User mentions "evroc" with "load balancer", "LB", "backend pool", or "health check"

**Do NOT use for:** compute VMs, networking (public IPs, security groups, subnets, VPCs), IAM, storage, or Think models.

## Prerequisites

Ensure the evroc CLI is installed:

```bash
bash scripts/check-cli.sh
```

Then authenticate:

```bash
bash scripts/check-auth.sh
```

A public IP must exist before creating a load balancer. Create it via **evroc-networking**:

```bash
evroc networking publicip create my-lb-ip
```

Note the subnet name when attaching the LB (managed via evroc-networking; defaults to
`default-<region>-<zone>`, e.g. `default-se-sto-a`).

## Load Balancer Lifecycle

Hierarchy: load balancer → listeners → L4 routes → backend services → backend pools → backends (VMs).

### 1. Create backend pool

```bash
evroc loadbalancer backendpool create my-pool \
  --backend-ref my-vm-1 \
  --backend-ref my-vm-2
```

### 2. Create backend service

```bash
evroc loadbalancer backendservice create my-service \
  --backend-pool-ref my-pool \
  --port 8080 \
  --ip-protocol-selection IPv4
```

### 3. Set health check

HTTP:

```bash
evroc loadbalancer backendservice sethealthcheckhttp my-service \
  --path /health \
  --target-port 8080 \
  --interval 10s \
  --timeout 5s \
  --healthy-threshold 2 \
  --unhealthy-threshold 3 \
  --expected-statuses 200 \
  --method GET
```

TCP:

```bash
evroc loadbalancer backendservice sethealthchecktcp my-service \
  --target-port 8080 \
  --interval 10s \
  --timeout 5s \
  --healthy-threshold 2 \
  --unhealthy-threshold 3
```

### 4. Create L4 route

```bash
evroc loadbalancer l4route create my-route \
  --backend-service-ref my-service
```

### 5. Create load balancer

```bash
evroc loadbalancer loadbalancer create my-lb \
  --public-ip-ref my-lb-ip
```

### 6. Add listener

```bash
evroc loadbalancer loadbalancer addlistener my-lb \
  --listener-name my-listener \
  --listener-port 443 \
  --listener-protocol TCP \
  --listener-route-ref my-route
```

**Completion criterion:** `evroc loadbalancer loadbalancer get my-lb -o yaml | grep -E '^\s+listeners:'` shows the listener attached.

## List and Inspect

```bash
# List all
evroc loadbalancer loadbalancer list

# With details
evroc loadbalancer loadbalancer list -o yaml

# Get specific
evroc loadbalancer loadbalancer get my-lb -o yaml

# List related resources
evroc loadbalancer backendpool list
evroc loadbalancer backendservice list
evroc loadbalancer l4route list
```

## Remove a Listener

```bash
evroc loadbalancer loadbalancer removelistener my-lb \
  --listener-name my-listener
```

## Delete Resources

Delete in reverse order: listener → load balancer → L4 route → backend service → backend pool.

HALT: Before running ANY `evroc loadbalancer ... delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

For load balancers: "This will permanently delete your Load Balancer
'<lb-name>' and cannot be undone."
For L4 routes: "This will permanently delete your L4 Route '<route-name>'
and cannot be undone."
For backend services: "This will permanently delete your Backend Service
'<service-name>' and cannot be undone."
For backend pools: "This will permanently delete your Backend Pool
'<pool-name>' and cannot be undone."

Then:
1. List ALL specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of the listed resources."
3. Wait for the user to explicitly type 'yes'

Do NOT run any delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc loadbalancer loadbalancer delete my-lb --force
evroc loadbalancer l4route delete my-route --force
evroc loadbalancer backendservice delete my-service --force
evroc loadbalancer backendpool delete my-pool --force
```

## Quota errors (InsufficientQuota)

Load balancer creation fails with HTTP 403 when the organization's load balancer quota is exhausted. The API response contains `reason: "InsufficientQuota"` and the text `not enough quota to perform request`. The load balancer count quota is separate from the public IP quota — a load balancer also needs a free public IP (see **evroc-networking**).

Committed quotas are org-wide: current usage in ANY project of the organization counts against the same limit.

HALT: When a `create` command fails with HTTP 403 and a body containing
"InsufficientQuota" (or the text "not enough quota to perform request"), you MUST:

1. Run: `bash scripts/check-quota.sh lbs` (or `evroc quotas orgquotas get`)
2. Report to the user VERBATIM: current load balancer usage and limit — e.g.
   "Load Balancers: 40/40 used — at limit"
3. State: "To request a quota increase, contact support@evroc.com"
4. Do NOT retry the command until the user decides (delete unused load balancers
   top-down: listener → load balancer → route → service → pool, or contact support).
   A silence or ambiguous response is NOT confirmation to retry.

## Pitfalls

- **Public IP required**: A load balancer requires a pre-existing public IP referenced by `--public-ip-ref`. Create it via **evroc-networking**.
- **Hierarchy order**: Create bottom-up (pool → service → route → load balancer → listener). Delete top-down.
- **Listener protocol**: Currently only `TCP` is supported for listener protocol.
- **Health check target-port**: The `--target-port` on a health check is the port on the backend VM, not the listener port. These can differ.
- **Backend references**: `--backend-ref` on a backend pool refers to VM names. Repeatable for multiple VMs.
- **Beta service**: The load balancer service is in beta. Command syntax and resource semantics may change between releases.
- **Labeling**: All load balancer resources support the `label` subcommand for adding/removing labels:
  `evroc loadbalancer <resource> label <name> --add key=value --remove key`.
  See [`references/cli-reference.md`](references/cli-reference.md) for details.
- **Load balancer quota (org-level)**: Load balancer count is limited by an org quota. Check real usage with
  `bash scripts/check-quota.sh lbs` or `evroc quotas orgquotas get`. To request an increase,
  contact support@evroc.com.
- **CLI aliases**: `lb` for `loadbalancer`, `bp` for `backendpool`, `bs` for `backendservice`, `l4r` for `l4route`, `ls` for `list`, `rm`/`del` for `delete`, `new` for `create`.
