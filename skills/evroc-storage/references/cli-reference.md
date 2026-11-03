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
| `--max-concurrent-requests` | int | Maximum number of concurrent requests (default: 5). |
| `--s3-credentials` | string | Path to S3 credentials file (default: `~/.evroc/credentials.ini`). |

### evroc storage bucket get-s3-credentials

```
evroc storage bucket get-s3-credentials [flags]
Aliases: get-s3-credentials, s3-creds
```

| Flag | Type | Description |
|---|---|---|
| `--duration` | duration | How long the S3 credentials are valid: 15m to 12h (default: `1h`). |
| `--path` | string | Output path for credentials (default: `~/.evroc/credentials.ini`). |

### evroc storage bucket update

```
evroc storage bucket update <name> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--default-object-lock-duration-days` | int | Days to retain locked objects (default: 1). Requires `--object-retention-mode=Locking`. |
| `--default-object-lock-mode` | string | Lock mode: `Soft` or `Immutable` (default: `Soft`). Requires `--object-retention-mode=Locking`. |
| `--lifecycle-policy` | string | Lifecycle policy in JSON. Use `file://` prefix to load from file. |
| `--object-retention-mode` | string | Retention mode: `Disabled`, `Suspended`, `Versioned`, `Locking` (default: `Disabled`). |

### evroc storage bucket label

Add or remove labels on a bucket.

```
evroc storage bucket label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

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

### evroc storage filestore label

Add or remove labels on a file store.

```
evroc storage filestore label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

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

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc storage bucketserviceaccount update

```
evroc storage bucketserviceaccount update <name> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--bucket` | strings | Bucket references to associate with the service account. |

### evroc storage bucketserviceaccount label

Add or remove labels on a bucket service account.

```
evroc storage bucketserviceaccount label <name> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (e.g. `key=value`). Default `[]`. |
| `-r, --remove` | strings | Label key to remove. Repeatable for multiple labels. |

## Bucket Service Account Secrets

### evroc storage bucketserviceaccountsecret

Manages secrets for bucket service accounts. Subcommand: `get`.

### evroc storage bucketserviceaccountsecret get

```
evroc storage bucketserviceaccountsecret get <name> [flags]
```

## KMS (Key Management)

Full flag reference for `evroc kms` key management commands. Key lifecycle:
`create` → (`rotate` \| `import-rotate`) → `suspend`/`activate` → `trim` → `delete`.
Delete and trim are two-phase operations with a grace period; each has an
`-abort` subcommand that reverses the operation while pending.

### evroc kms keys create

```
evroc kms keys create <key_id> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--algorithm` | string | Kind of key to create (default: `aes256-gcm96`). |
| `--auto-rotate-days` | int32 | Auto-rotate key versions at this interval in days (default: `-1`, disabled). |
| `--expiration-days` | int32 | Expire key versions after this period in days (default: `-1`, disabled). |
| `--imported` | bool | Create a key for importing key material (see `import`). |

### evroc kms keys list / get

```
evroc kms keys list [flags]
Aliases: list, ls
evroc kms keys get <key_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector (list only). |
| `-o, --out` | string | Output: `list` (default on list), `yaml` (default on get), `json`. |

### evroc kms keys rotate

Generates a new key version that becomes the default. Previous versions remain
valid until trimmed.

```
evroc kms keys rotate <key_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts and execute destructive actions. |

### evroc kms keys import / import-rotate

Import key material into a key that was created with `--imported`. Material is
wrapped locally with an ephemeral data key — plaintext never leaves the machine.
`import-rotate` rotates an imported key by importing new material.

```
evroc kms keys import <key_id> [flags]
evroc kms keys import-rotate <key_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts (`import-rotate` only). |
| `--path` | string | Path to the raw key material to import. |

### evroc kms keys suspend / activate

```
evroc kms keys suspend <key_id> [flags]
evroc kms keys activate <key_id> [flags]
```

`suspend` makes the key unusable (reversible — `activate` restores it; keys may
also be `activate`d when pre-activated).

### evroc kms keys trim / trim-abort

Trim suspends all versions below `--min-version-to-keep` immediately; they are
permanently purged after a grace period. `trim-abort` re-activates versions that
are still pending final trim. The latest/current version cannot be trimmed.

```
evroc kms keys trim <key_id> [flags]
evroc kms keys trim-abort <key_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts (trim only). |
| `--min-version-to-keep` | uint | Minimum version to keep (trim only, required). |

### evroc kms keys delete / delete-abort

Delete moves the key to "Pending Deletion" (unusable for encryption or
decryption); the key is permanently deleted after a grace period. `delete-abort`
restores a key that is still pending deletion.

```
evroc kms keys delete <key_id> [flags]
Aliases: delete, del, rm
evroc kms keys delete-abort <key_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts (delete only). |

## Object Retention Modes

| Mode | Description |
|---|---|
| `Disabled` | No retention (default). Objects can be deleted freely. |
| `Suspended` | Versioning is suspended. |
| `Versioned` | All object versions are kept. Deleted objects get a deletion marker. |
| `Locking` | Object lock enabled. Requires `--default-object-lock-mode` and `--default-object-lock-duration-days`. Objects cannot be deleted until lock expires. |

## S3 Compatibility

Buckets are S3-compatible. After running `evroc storage bucket get-s3-credentials`, you can use any S3 client (aws-cli, rclone, s3cmd) with the credentials at `~/.evroc/credentials.ini` and the S3 endpoint from `~/.evroc/config.yaml` (`s3URL` field).
