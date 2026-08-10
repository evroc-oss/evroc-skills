---
name: evroc-loadbalancer
description: "Manage evroc load balancers: create and configure load balancers, backend pools, backend services, L4 routes, and listeners via the evroc CLI. Use when the user wants to set up load balancing for VMs, configure health checks, or manage traffic routing on evroc cloud."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux. Load balancer is a beta feature."
metadata:
  author: evroc
  version: "1.0"
  category: infrastructure
allowed-tools: terminal
---

# evroc-loadbalancer

Manage evroc load balancers through the `evroc loadbalancer` CLI. Covers load balancer creation, backend pools, backend services, health checks, L4 routes, and listeners. This service is currently in beta.

For full CLI flag reference, read [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create or manage a load balancer on evroc
- User wants to configure backend pools with VM backends
- User wants to set up health checks (HTTP or TCP) for backend services
- User wants to configure L4 routes and listeners for traffic distribution
- User mentions "evroc" with "load balancer", "LB", "backend pool", or "health check"

## Prerequisites

The evroc CLI must be installed and authenticated:

```bash
evroc login
```

A public IP and subnet must exist before creating a load balancer. Create them first:

```bash
# Create a public IP
evroc networking publicip create my-lb-ip

# Note the subnet name (format: default-<region>-<zone>, e.g. default-se-sto-a)
```

## Load Balancer Lifecycle

A load balancer has a hierarchy: load balancer → listeners → L4 routes → backend services → backend pools → backends (VMs).

### 1. Create backend pool (groups VMs)

```bash
evroc loadbalancer backendpool create my-pool \
  --backend-ref my-vm-1 \
  --backend-ref my-vm-2
```

### 2. Create backend service (defines port + protocol)

```bash
evroc loadbalancer backendservice create my-service \
  --backend-pool-ref my-pool \
  --port 8080 \
  --ip-protocol-selection IPv4
```

### 3. Set health check (optional but recommended)

HTTP health check:

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

TCP health check:

```bash
evroc loadbalancer backendservice sethealthchecktcp my-service \
  --target-port 8080 \
  --interval 10s \
  --timeout 5s \
  --healthy-threshold 2 \
  --unhealthy-threshold 3
```

### 4. Create L4 route (routes traffic to a backend service)

```bash
evroc loadbalancer l4route create my-route \
  --backend-service-ref my-service
```

### 5. Create load balancer

```bash
evroc loadbalancer loadbalancer create my-lb \
  --public-ip-ref my-lb-ip
```

### 6. Add a listener (exposes a port on the load balancer)

```bash
evroc loadbalancer loadbalancer addlistener my-lb \
  --listener-name my-listener \
  --listener-port 443 \
  --listener-protocol TCP \
  --listener-route-ref my-route
```

**Completion criterion:** `evroc loadbalancer loadbalancer get my-lb` returns the load balancer with the listener, route, service, and pool attached.

## List and Inspect

### List load balancers

```bash
evroc loadbalancer loadbalancer list

# With details
evroc loadbalancer loadbalancer list -o yaml
```

### Get load balancer details

```bash
evroc loadbalancer loadbalancer get my-lb
```

### List backend pools

```bash
evroc loadbalancer backendpool list
```

### List backend services

```bash
evroc loadbalancer backendservice list
```

### List L4 routes

```bash
evroc loadbalancer l4route list
```

## Remove a Listener

```bash
evroc loadbalancer loadbalancer removelistener my-lb \
  --listener-name my-listener
```

## Delete Resources

Delete in reverse order: listener → load balancer → L4 route → backend service → backend pool.

```bash
evroc loadbalancer loadbalancer delete my-lb --force
evroc loadbalancer l4route delete my-route
evroc loadbalancer backendservice delete my-service
evroc loadbalancer backendpool delete my-pool
```

## Pitfalls

- **Beta feature**: The load balancer service is in beta. Command syntax may change between releases.
- **Public IP required**: A load balancer requires a pre-existing public IP referenced by `--public-ip-ref`.
- **Hierarchy order**: Create resources bottom-up: pool → service → route → load balancer → listener. Delete top-down.
- **Listener protocol**: Currently only `TCP` is supported for listener protocol.
- **Health check ports**: The `--target-port` on a health check is the port on the backend VM, not the listener port. These can differ.
- **Backend references**: `--backend-ref` on a backend pool refers to VM names. Repeatable for multiple VMs.
- **CLI aliases**: `lb` for `loadbalancer`, `bp` for `backendpool`, `bs` for `backendservice`, `l4r` for `l4route`, `ls` for `list`, `rm`/`del` for `delete`, `new` for `create`.
