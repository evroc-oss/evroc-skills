# CLI Reference

Full flag reference for `evroc compute` commands. All commands inherit `--config string` (path to evroc config file, default `~/.evroc/config.yaml`).

## Virtual Machines

### evroc compute vm create

```
evroc compute virtualmachine create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--boot-from` | bools | Whether this disk should be booted from. Must be specified for every disk. |
| `--cloud-init-user-data` | string | CloudInit user data — base64 string or multi-line string. |
| `--disk` | strings | Name of disk to attach. Repeatable for multiple disks. |
| `--placement-group` | string | Name of placement group to use. |
| `--public-ip` | string | Public IP to assign. |
| `--running` | bool | Whether the VM should be running (default: true). |
| `--security-group` | strings | Security group name. Repeatable for multiple groups. |
| `--ssh-authorized-key` | strings | Public key for SSH access. Repeatable for multiple keys. |
| `--stack-type` | string | Network stack: `dual-stack`, `ipv6-only`, `ipv4-only`. |
| `--subnet` | string | Name of subnet to attach VM to. |
| `--vm-virtual-resources-ref` | string | Compute profile: `<series>.<size>` (e.g. `a1a.m`). |
| `--zone` | string | Zone. |

### evroc compute vm list

```
evroc compute virtualmachine list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc compute vm get

```
evroc compute virtualmachine get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc compute vm update

```
evroc compute virtualmachine update <name> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--append` | bool | Additive changes to lists (disks, security groups). |
| `--boot-from` | bools | Whether disk should be booted from. Per disk. |
| `--disk` | strings | Disk to attach. Repeatable. |
| `--placement-group` | string | Placement group name. |
| `--public-ip` | string | Public IP to assign. |
| `--running` | bool | Whether VM should be running (default: true). |
| `--security-group` | strings | Security group name. Repeatable. |

### evroc compute vm delete

```
evroc compute virtualmachine delete <name> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

## Disks

### evroc compute disk create

```
evroc compute disk create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--image` | string | Name of the disk image. |
| `--size-amount` | int | Size of disk in the related unit. |
| `--size-unit` | string | One of `KB`, `MB`, `GB`, `TB`. |
| `--snapshot` | string | Name of snapshot to create from. |
| `--zone` | string | Zone. |

### evroc compute disk list

```
evroc compute disk list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc compute disk get

```
evroc compute disk get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc compute disk delete

```
evroc compute disk delete <name> [flags]
Aliases: delete, del, rm
```

### evroc compute disk update

```
evroc compute disk update <name> [flags]
Aliases: update, u
```

## Snapshots

### evroc compute snapshot create

```
evroc compute snapshot create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--disk-ref` | string | Name of the disk to snapshot. |

### evroc compute snapshot list

```
evroc compute snapshot list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc compute snapshot get

```
evroc compute snapshot get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc compute snapshot delete

```
evroc compute snapshot delete <name> [flags]
Aliases: delete, del, rm
```

## Placement Groups

### evroc compute placementgroup create

```
evroc compute placementgroup create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--strategy-type` | string | Strategy type (e.g. `spread`). |
| `--zone` | string | Zone. |

### evroc compute placementgroup list

```
evroc compute placementgroup list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc compute placementgroup get

```
evroc compute placementgroup get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc compute placementgroup delete

```
evroc compute placementgroup delete <name> [flags]
Aliases: delete, del, rm
```

## Compute Profile Format

Compute profiles (`--vm-virtual-resources-ref`) use the format `<series>.<size>`:

| Series | Type | Sizes |
|---|---|---|
| `a1a` | General purpose | `xs`, `s`, `m`, `l`, `xl`, `2xl` |
| `c1a` | Compute optimized | `xs`, `s`, `m`, `l`, `xl`, `2xl` |
| `m1a` | Memory optimized | `xs`, `s`, `m`, `l`, `xl`, `2xl` |

Example: `a1a.m` = general purpose, medium size.

See the [evroc compute documentation](https://docs.evroc.com/products/compute/index.html) for the authoritative list of supported profiles.
