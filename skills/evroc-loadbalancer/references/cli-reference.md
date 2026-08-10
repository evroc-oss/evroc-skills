# CLI Reference

Full flag reference for `evroc loadbalancer` commands. All commands inherit `--config string` (path to evroc config file, default `~/.evroc/config.yaml`).

## Load Balancers

### evroc loadbalancer lb create

```
evroc loadbalancer loadbalancer create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--public-ip-ref` | string | Public IP reference (required). |
| `--subnet` | strings | Backend subnet as `zone:subnet` (e.g. `a:my-subnet`). Repeatable, one per zone. Required when `--vpc` is set. |
| `--vpc` | string | VPC the load balancer attaches to. Required when `--subnet` is set. |

### evroc loadbalancer lb list

```
evroc loadbalancer loadbalancer list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc loadbalancer lb get

```
evroc loadbalancer loadbalancer get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc loadbalancer lb delete

```
evroc loadbalancer loadbalancer delete <name> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc loadbalancer lb addlistener

```
evroc loadbalancer loadbalancer addlistener <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--listener-name` | string | Name of the listener, unique per LB (required). |
| `--listener-port` | int | Listening port 1-65535 (required). |
| `--listener-protocol` | string | Protocol: `TCP` (default: `TCP`). |
| `--listener-route-ref` | strings | Route references (repeatable). |

### evroc loadbalancer lb removelistener

```
evroc loadbalancer loadbalancer removelistener <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--listener-name` | string | Name of the listener to remove (required). |

## Backend Pools

### evroc loadbalancer bp create

```
evroc loadbalancer backendpool create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--backend-ref` | strings | Reference to a backend VM (repeatable). |

### evroc loadbalancer bp list

```
evroc loadbalancer backendpool list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc loadbalancer bp get

```
evroc loadbalancer backendpool get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc loadbalancer bp delete

```
evroc loadbalancer backendpool delete <name> [flags]
Aliases: delete, del, rm
```

### evroc loadbalancer bp update

```
evroc loadbalancer backendpool update <name> [flags]
Aliases: update, u
```

## Backend Services

### evroc loadbalancer bs create

```
evroc loadbalancer backendservice create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--backend-pool-ref` | string | Reference to the backend pool. |
| `--ip-protocol-selection` | string | IP protocol: `IPv4` or `IPv6`. |
| `--port` | int | Listening port 1-65535. |
| `--proxy-protocol` | bool | Enable proxy protocol. |

### evroc loadbalancer bs list

```
evroc loadbalancer backendservice list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc loadbalancer bs get

```
evroc loadbalancer backendservice get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc loadbalancer bs delete

```
evroc loadbalancer backendservice delete <name> [flags]
Aliases: delete, del, rm
```

### evroc loadbalancer bs sethealthcheckhttp

```
evroc loadbalancer backendservice sethealthcheckhttp <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--expected-statuses` | uints | HTTP status codes considered healthy (repeatable). |
| `--healthy-threshold` | uint32 | Successes required to mark healthy. |
| `--host` | string | HTTP Host header value. |
| `--interval` | duration | Time between checks (e.g. `10s`). |
| `--method` | string | HTTP method: `GET` or `HEAD` (default: `GET`). |
| `--path` | string | Request path (required). |
| `--target-port` | uint32 | Backend port to check. |
| `--timeout` | duration | Time allowed per check (e.g. `5s`). |
| `--unhealthy-threshold` | uint32 | Failures required to mark unhealthy. |

### evroc loadbalancer bs sethealthchecktcp

```
evroc loadbalancer backendservice sethealthchecktcp <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--healthy-threshold` | uint32 | Successes required to mark healthy. |
| `--interval` | duration | Time between checks. |
| `--receive` | string | Expected response payload. |
| `--send` | string | Payload to send after connecting. |
| `--target-port` | uint32 | Backend port to check. |
| `--timeout` | duration | Time allowed per check. |
| `--unhealthy-threshold` | uint32 | Failures required to mark unhealthy. |

### evroc loadbalancer bs clearhealthcheck

```
evroc loadbalancer backendservice clearhealthcheck <name> [flags]
```

## L4 Routes

### evroc loadbalancer l4r create

```
evroc loadbalancer l4route create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--backend-service-ref` | string | Reference to the default backend service (required). |

### evroc loadbalancer l4r list

```
evroc loadbalancer l4route list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc loadbalancer l4r get

```
evroc loadbalancer l4route get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc loadbalancer l4r delete

```
evroc loadbalancer l4route delete <name> [flags]
Aliases: delete, del, rm
```

## Resource Hierarchy

```
Load Balancer
└── Listener (port + protocol)
    └── L4 Route
        └── Backend Service (port + protocol + health check)
            └── Backend Pool
                └── Backend (VM reference)
```

Create bottom-up, delete top-down.
