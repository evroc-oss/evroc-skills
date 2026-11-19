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
| `--stack-type` | string | Network stack: `dual-stack`, `ipv6-only`. `ipv4-only` is deprecated. |
| `--subnet` | string | Name of subnet to attach VM to. |
| `--compute-profile-ref` | string | Compute profile: `<series>.<size>` (e.g. `a1a.m`). `--vm-virtual-resources-ref` is a backwards-compatible alias. |
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

### evroc compute virtualmachine label

Add or remove labels on a VM.

```
evroc compute virtualmachine label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

## Disks

### evroc compute disk create

```
evroc compute disk create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--custom-image` | string | Name of a custom (user-uploaded) disk image. See [Custom Disk Images](#custom-disk-images) below. |
| `--image` | string | Name of a platform-provided disk image. See [Available Disk Images](#available-disk-images) below. |
| `--size-amount` | int | Size of disk in the related unit. |
| `--size-unit` | string | One of `KB`, `MB`, `GB`, `TB`. |
| `--snapshot` | string | Name of snapshot to create from. |
| `--zone` | string | Zone. |

#### Available Disk Images

The `--image` flag accepts the platform catalog names below. The live,
authoritative list is `evroc compute diskimage list` — present its output and
let the user choose. (Check custom user-uploaded images with
`evroc compute customdiskimage list` — those go to `--custom-image`, not `--image`.)

| Image Name | Distro | Version | Default Size |
|---|---|---|---|
| `ubuntu-minimal.26-04.1` | Minimal Ubuntu | 26.04 | 5 GB |
| `ubuntu-minimal.24-04.1` | Minimal Ubuntu | 24.04 | 5 GB |
| `ubuntu.26-04.1` | Ubuntu | 26.04 | 50 GB |
| `ubuntu.24-04.1` | Ubuntu | 24.04 | 50 GB |
| `ubuntu.22-04.1` | Ubuntu | 22.04 | 50 GB |
| `rocky.10-1.1` | Rocky Linux | 10.1 | 50 GB |
| `rocky.9-6.1` | Rocky Linux | 9.6 | 50 GB |
| `rocky.8-10.1` | Rocky Linux | 8.10 | 50 GB |
| `opensuse.16-0.1` | openSUSE | 16.0 | 50 GB |
| `opensuse.15-6.1` | openSUSE | 15.6 | 50 GB |
| `opensuse.15-5.1` | openSUSE | 15.5 | 50 GB |
| `sles.16-0.1` | SLES | 16.0 | not listed — verify with `diskimage get` |
| `sles.15-6.1` | SLES | 15.6 | 50 GB |
| `sles.15-5.1` | SLES | 15.5 | 50 GB |
| `sl-micro.6-1.1` | SL Micro | 6.1 | 50 GB |

> GPU VMs only support Ubuntu 24.04 or custom disk images.

Image name format: `<distro>.<version>.1` (dot before version, hyphen within version). Using wrong separators (e.g. `ubuntu-minimal-24.04.1`) silently creates a disk that never becomes Ready (`DiskImageInvalid`).

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

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc compute disk update

```
evroc compute disk update <name> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--size-amount` | int | New size (can only increase). |
| `--size-unit` | string | One of: `KB`, `MB`, `GB`, `TB`. |

### evroc compute disk label

Add or remove labels on a disk.

```
evroc compute disk label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

### evroc compute diskimage list

Lists the platform-provided disk image catalog (the authoritative image list).

```
evroc compute diskimage list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `list` (default), `yaml`, `json`. |

`evroc compute diskimage get <image-name>` returns full details for one image
(`-o yaml|json|list`, default `yaml`).

## Custom Disk Images

Custom disk images are user-uploaded OS images stored as objects in an evroc
storage bucket. Register them with `evroc compute customdiskimage` and reference
them via `--custom-image` on `evroc compute disk create` (NOT `--image`, which
is reserved for the platform catalog above).

### evroc compute customdiskimage create

```
evroc compute customdiskimage create <image_id> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--architecture` | string | Image architecture: `amd64`. |
| `--bucket` | string | Name of the bucket where the image is stored. |
| `--description` | string | Optional description. |
| `--image-version` | string | Optional image version. |
| `--os-name` | string | Optional OS name. |
| `--os-version` | string | Optional OS version. |
| `--path` | string | Path of the image in the bucket. |
| `--service-account` | string | Service account name for accessing the bucket. |
| `--size-amount` | int32 | Default disk size amount. |
| `--size-unit` | string | Default disk size unit: `KB`, `MB`, `GB`, `TB`. |
| `--version` | string | Image version to use (defaults to latest). |

### evroc compute customdiskimage list / get

```
evroc compute customdiskimage list [flags]
evroc compute customdiskimage get <image_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector (list only). |
| `-o, --out` | string | Output: `list` (default on list), `yaml` (default on get), `json`. |

### evroc compute customdiskimage update

```
evroc compute customdiskimage update <image_id> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--description` | string | Optional description. |
| `--image-version` | string | Optional image version. |
| `--os-name` | string | Optional OS name. |
| `--os-version` | string | Optional OS version. |

### evroc compute customdiskimage label

```
evroc compute customdiskimage label <image_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable. |

### evroc compute customdiskimage delete

```
evroc compute customdiskimage delete <image_id> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

## Hotswap Disk Attachments

Hotswap disk attachments allow attaching a disk to a running VM without rebooting.

### evroc compute hotswapdiskattachment create

```
evroc compute hotswapdiskattachment create <hotswapdiskattachment_id> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--disk-ref` | string | Disk reference to attach. |
| `--vm-ref` | string | VM reference to attach to. |

### evroc compute hotswapdiskattachment list

```
evroc compute hotswapdiskattachment list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc compute hotswapdiskattachment get

```
evroc compute hotswapdiskattachment get <hotswapdiskattachment_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc compute hotswapdiskattachment update

```
evroc compute hotswapdiskattachment update <hotswapdiskattachment_id> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--disk-ref` | string | Disk reference to attach. |
| `--vm-ref` | string | VM reference to attach to. |

### evroc compute hotswapdiskattachment delete

```
evroc compute hotswapdiskattachment delete <hotswapdiskattachment_id> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts and execute destructive actions. |

### evroc compute hotswapdiskattachment label

```
evroc compute hotswapdiskattachment label <hotswapdiskattachment_id> [flags]
Aliases: label
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

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

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc compute snapshot label

Add or remove labels on a snapshot.

```
evroc compute snapshot label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

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

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc compute placementgroup label

Add or remove labels on a placement group.

```
evroc compute placementgroup label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

## Compute Profile Format

Compute profiles (`--compute-profile-ref`) use the format `<series>.<size>`:

| Series | Type | Sizes |
|---|---|---|
| `a1a` | General purpose | `xs`, `s`, `m`, `l`, `xl`, `2xl` |
| `c1a` | Compute optimized | `xs`, `s`, `m`, `l`, `xl`, `2xl` |
| `m1a` | Memory optimized | `xs`, `s`, `m`, `l`, `xl`, `2xl` |

Example: `a1a.m` = general purpose, medium size.

`--vm-virtual-resources-ref` is accepted as a backwards-compatible alias for
`--compute-profile-ref`.

For the authoritative list of supported profiles, run
`evroc compute computeprofile list` (and `evroc compute computeprofile get
<profile>` for details). See also the [evroc compute documentation](https://docs.evroc.com/products/compute/index.html).
