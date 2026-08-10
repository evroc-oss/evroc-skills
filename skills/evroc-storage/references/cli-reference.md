# CLI Reference

Full flag reference for `evroc storage` commands. All commands inherit `--config string` (path to evroc config file, default `~/.evroc/config.yaml`).

## Buckets

### evroc storage bucket create

```
evroc storage bucket create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--default-object-lock-duration-days` | int | Days to retain locked objects (default: 1). Requires `--object-retention-mode=Locking`. |
| `--default-object-lock-mode` | string | Lock mode: `Soft` or `Immutable` (default: `Soft`). Requires `--object-retention-mode=Locking`. |
| `--lifecycle-policy` | string | Lifecycle policy in JSON. Use `file://` prefix to load from file. |
| `--object-retention-mode` | string | Retention mode: `Disabled`, `Suspended`, `Versioned`, `Locking` (default: `Disabled`). |

### evroc storage bucket list

```
evroc storage bucket list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-A, --include-all` | bool | Include all (including old and deleted) versions. |
| `-D, --include-deleted` | bool | Include deleted object versions. |
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |
| `--s3-credentials` | string | Path to S3 credentials file (default: `~/.evroc/credentials.ini`). |

### evroc storage bucket get

```
evroc storage bucket get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc storage bucket delete

```
evroc storage bucket delete [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |
| `--purge` | bool | Purge all objects before deleting the bucket. |
| `--s3-credentials` | string | Path to S3 credentials file (default: `~/.evroc/credentials.ini`). |

Can delete by bucket name or by `bucket://<bucket>/<object>` path.

### evroc storage bucket copy

```
evroc storage bucket copy [flags]
Aliases: copy, cp
```

| Flag | Type | Description |
|---|---|---|
| `-f, --from` | string | Source: local file or `bucket://<bucket>/<object>`. |
| `-t, --to` | string | Destination: local file or `bucket://<bucket>/<object>`. |
| `--s3-credentials` | string | Path to S3 credentials file (default: `~/.evroc/credentials.ini`). |

### evroc storage bucket get-s3-credentials

```
evroc storage bucket get-s3-credentials [flags]
Aliases: get-s3-credentials, s3-creds
```

| Flag | Type | Description |
|---|---|---|
| `--path` | string | Output path for credentials (default: `~/.evroc/credentials.ini`). |

### evroc storage bucket update

```
evroc storage bucket update <name> [flags]
Aliases: update, u
```

### evroc storage bucket label

```
evroc storage bucket label <name> [flags]
```

## File Stores

### evroc storage filestore create

```
evroc storage filestore create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--zone` | string | Availability zone (required). |

### evroc storage filestore list

```
evroc storage filestore list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc storage filestore get

```
evroc storage filestore get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc storage filestore delete

```
evroc storage filestore delete <name> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

## Bucket Service Accounts

### evroc storage bucketserviceaccount create

```
evroc storage bucketserviceaccount create <name> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `-b, --bucket` | strings | Bucket IDs the SA has access to (repeatable). |

### evroc storage bucketserviceaccount list

```
evroc storage bucketserviceaccount list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc storage bucketserviceaccount get

```
evroc storage bucketserviceaccount get <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc storage bucketserviceaccount delete

```
evroc storage bucketserviceaccount delete <name> [flags]
Aliases: delete, del, rm
```

### evroc storage bucketserviceaccount update

```
evroc storage bucketserviceaccount update <name> [flags]
Aliases: update, u
```

## Bucket Service Account Secrets

### evroc storage bucketserviceaccountsecret

Manages secrets for bucket service accounts. Subcommands: `create`, `delete`, `get`, `label`, `list`, `update`.

## Object Retention Modes

| Mode | Description |
|---|---|
| `Disabled` | No retention (default). Objects can be deleted freely. |
| `Suspended` | Versioning is suspended. |
| `Versioned` | All object versions are kept. Deleted objects get a deletion marker. |
| `Locking` | Object lock enabled. Requires `--default-object-lock-mode` and `--default-object-lock-duration-days`. Objects cannot be deleted until lock expires. |

## S3 Compatibility

Buckets are S3-compatible. After running `evroc storage bucket get-s3-credentials`, you can use any S3 client (aws-cli, rclone, s3cmd) with the credentials at `~/.evroc/credentials.ini` and the S3 endpoint from `~/.evroc/config.yaml` (`s3URL` field).
