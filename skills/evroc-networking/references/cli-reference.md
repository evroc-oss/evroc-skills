# CLI Reference

Full flag reference for `evroc networking` commands. All commands inherit `--config string` (path to evroc config file, default `~/.evroc/config.yaml`).

CLI aliases: `net` for `networking`, `sg` for `securitygroup`, `vpc` for `virtualprivatecloud`, `ip` for `publicip`.

## VPCs

### evroc networking vpc create

```
evroc networking vpc create <name> [flags]
Aliases: vpc = virtualprivatecloud, create, new
```

| Flag | Type | Description |
|---|---|---|
| `--ipv4-cidr-block` | string | IPv4 CIDR block for the VPC. Must be RFC 1918 private range (e.g. `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`). |
| `--stack-type` | string | Network stack type: `dual-stack`, `ipv6-only`, `ipv4-only`. |

### evroc networking vpc list

```
evroc networking vpc list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc networking vpc get

```
evroc networking vpc get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc networking vpc delete

```
evroc networking vpc delete <name> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

## Subnets

### evroc networking subnet create

```
evroc networking subnet create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--ipv4-cidr-block` | string | IPv4 CIDR block for the subnet (e.g. `10.0.0.0/24`). |
| `--stack-type` | string | Network stack type: `dual-stack`, `ipv6-only`, `ipv4-only`. |
| `--vpc` | string | Name of the parent VPC (required). |
| `--zone` | string | Availability zone (required, e.g. `a`, `b`). |

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

## Security Groups

### evroc networking securitygroup create

```
evroc networking securitygroup create <name> [flags]
Aliases: sg = securitygroup, create, new
```

| Flag | Type | Description |
|---|---|---|
| `--vpc` | string | Name of the VPC to associate with this security group. |

### evroc networking securitygroup addrule

```
evroc networking securitygroup addrule <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--direction` | string | Traffic direction: `Ingress` or `Egress`. |
| `--name` | string | Name of the rule. |
| `--port` | int | Port number. Use `0` for all ports. |
| `--end-port` | int | End of port range (for port ranges). Optional. |
| `--protocol` | string | Protocol: `All`, `TCP`, `UDP`, or `ICMP`. |
| `--remote-ip-or-cidr` | string | Remote IP address or CIDR block (e.g. `0.0.0.0/0`, `10.0.0.0/24`). |
| `--security-group` | string | Reference to another security group by name. |
| `--subnet` | string | Reference to a subnet by name. |

> **Mutually exclusive sources:** Use exactly one of `--remote-ip-or-cidr`, `--security-group`, or `--subnet` per rule. Combining multiple source flags is an error.

### evroc networking securitygroup removerule

```
evroc networking securitygroup removerule <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--direction` | string | Traffic direction: `Ingress` or `Egress`. |
| `--name` | string | Name of the rule. |
| `--port` | int | Port number. Use `0` for all ports. |
| `--end-port` | int | End of port range (for port ranges). Optional. |
| `--protocol` | string | Protocol: `All`, `TCP`, `UDP`, or `ICMP`. |
| `--remote-ip-or-cidr` | string | Remote IP address or CIDR block. |
| `--security-group` | string | Reference to another security group by name. |
| `--subnet` | string | Reference to a subnet by name. |

> **Mutually exclusive sources:** Use exactly one of `--remote-ip-or-cidr`, `--security-group`, or `--subnet` per rule.

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

## Public IPs

### evroc networking publicip create

```
evroc networking publicip create <name> [flags]
Aliases: ip = publicip, create, new
```

No additional flags. Each account has a quota of 3 public IPs.

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

## Security Group Rule Reference

### Direction

| Value | Description |
|---|---|
| `Ingress` | Inbound traffic (incoming to the resource). |
| `Egress` | Outbound traffic (leaving from the resource). |

### Protocol

| Value | Description |
|---|---|
| `All` | All protocols (TCP, UDP, ICMP). Use with `--port=0` for unrestricted. |
| `TCP` | TCP protocol only. |
| `UDP` | UDP protocol only. |
| `ICMP` | ICMP protocol only (ping). |

### Port

| Value | Description |
|---|---|
| `0` | All ports. |
| `1-65535` | Specific port number. |
| `--port` + `--end-port` | Port range (e.g. `--port=8000 --end-port=8100`). |

### Rule Sources (mutually exclusive)

| Flag | Example | Description |
|---|---|---|
| `--remote-ip-or-cidr` | `0.0.0.0/0`, `10.0.0.0/24`, `::/0` | Allow traffic from an IP address or CIDR block. |
| `--security-group` | `my-other-sg` | Allow traffic from resources in another security group. |
| `--subnet` | `default-se-sto-a` | Allow traffic from resources in a specific subnet. |

## Stack Types

| Stack Type | Description |
|---|---|
| `dual-stack` | Both IPv4 and IPv6 (recommended). |
| `ipv4-only` | IPv4 only. |
| `ipv6-only` | IPv6 only. |
