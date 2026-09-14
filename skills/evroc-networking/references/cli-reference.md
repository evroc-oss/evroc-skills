# CLI Reference

Full flag reference for `evroc networking` commands. All commands inherit `--config string` (path to evroc config file, default `~/.evroc/config.yaml`).

## Public IPs

### evroc networking publicip create

```
evroc networking publicip create <name> [flags]
Aliases: create, new
```

### evroc networking publicip list

```
evroc networking publicip list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc networking publicip get

```
evroc networking publicip get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc networking publicip delete

```
evroc networking publicip delete <name> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc networking publicip label

Add or remove labels on a public IP.

```
evroc networking publicip label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

## Security Groups

### evroc networking securitygroup create

```
evroc networking securitygroup create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--vpc` | string | Name of the VPC for this security group. |

### evroc networking securitygroup list

```
evroc networking securitygroup list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc networking securitygroup get

```
evroc networking securitygroup get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc networking securitygroup delete

```
evroc networking securitygroup delete <name> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc networking securitygroup addrule

```
evroc networking securitygroup addrule <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--direction` | string | Direction of traffic: `Ingress` or `Egress`. |
| `--end-port` | int | End of port range; use with `--port` as start (e.g. `--port=8000 --end-port=8100`). |
| `--name` | string | Name of the rule. Must be unique per security group. |
| `--port` | int | Port the rule applies to (empty or `0` indicates all ports). |
| `--protocol` | string | Protocol: `All`, `TCP`, `UDP`, `ICMP`. |
| `--remote-ip-or-cidr` | string | IP address or CIDR block. Should not be specified with `--security-group` or `--subnet`. |
| `--security-group` | string | Name of the security group for traffic source/dest. Alternative to positional argument. |
| `--subnet` | string | Name of the subnet for traffic source/dest. Should not be specified with `--remote-ip-or-cidr` or `--security-group`. |

### evroc networking securitygroup removerule

```
evroc networking securitygroup removerule <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--name` | string | Name of the rule to remove. |

### evroc networking securitygroup label

Add or remove labels on a security group.

```
evroc networking securitygroup label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

## Subnets

### evroc networking subnet create

```
evroc networking subnet create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--ipv4-cidr-block` | string | IPv4 CIDR block (required for dual-stack). |
| `--stack-type` | string | Stack type: `dual-stack` or `ipv6-only`. |
| `--vpc` | string | Name of the VPC to create the subnet in. |
| `--zone` | string | Zone for the subnet. |

### evroc networking subnet list

```
evroc networking subnet list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc networking subnet get

```
evroc networking subnet get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc networking subnet delete

```
evroc networking subnet delete <name> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc networking subnet label

Add or remove labels on a subnet.

```
evroc networking subnet label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

## VPCs (Virtual Private Clouds)

### evroc networking vpc create

```
evroc networking virtualprivatecloud create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--ipv4-cidr-block` | string | IPv4 CIDR block for the VPC (RFC 1918). |
| `--stack-type` | string | Stack type: `dual-stack` or `ipv6-only`. |

### evroc networking vpc list

```
evroc networking virtualprivatecloud list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc networking vpc get

```
evroc networking virtualprivatecloud get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc networking vpc delete

```
evroc networking virtualprivatecloud delete <name> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc networking vpc label

Add or remove labels on a VPC.

```
evroc networking virtualprivatecloud label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |
