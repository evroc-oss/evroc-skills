---
name: evroc-storage
description: "Manage evroc storage resources: object storage buckets, S3 credentials, file stores, and bucket service accounts via the evroc CLI. Use when the user wants to create, list, inspect, or delete buckets, copy objects to/from buckets, manage file stores, or set up S3 access."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.0"
  category: infrastructure
allowed-tools: terminal
---

# evroc-storage

Manage evroc storage resources through the `evroc storage` CLI. Covers object storage (S3-compatible buckets), file stores (NFS), and bucket service accounts.

For full CLI flag reference, read [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, or delete an S3-compatible bucket
- User wants to copy files to or from a bucket
- User wants to get S3 credentials for programmatic access
- User wants to create or manage a file store (NFS)
- User wants to create a bucket service account for bucket access
- User mentions "evroc" with "bucket", "storage", "S3", "file store", or "object storage"

## Prerequisites

The evroc CLI must be installed and authenticated:

```bash
evroc login
```

Verify auth:

```bash
cat ~/.evroc/config.yaml
```

## Object Storage (Buckets)

### List buckets

```bash
evroc storage bucket list

# With details
evroc storage bucket list -o yaml

# Filter by label
evroc storage bucket list -l "environment=production"
```

### Get bucket details

```bash
evroc storage bucket get <bucket-name>
```

### Create a bucket

```bash
evroc storage bucket create my-bucket
```

With object versioning:

```bash
evroc storage bucket create my-bucket \
  --object-retention-mode=Versioned
```

With object locking:

```bash
evroc storage bucket create my-bucket \
  --object-retention-mode=Locking \
  --default-object-lock-mode=Soft \
  --default-object-lock-duration-days=30
```

With a lifecycle policy (JSON):

```bash
evroc storage bucket create my-bucket \
  --lifecycle-policy=file://lifecycle-policy.json
```

### Get S3 credentials

Before copying objects or using S3 clients, retrieve S3 credentials:

```bash
evroc storage bucket get-s3-credentials

# Credentials are written to ~/.evroc/credentials.ini by default
# Specify a custom path:
evroc storage bucket get-s3-credentials --path /tmp/s3-creds.ini
```

### Copy objects to/from a bucket

```bash
# Upload a local file to a bucket
evroc storage bucket copy --from /path/to/local/file --to bucket://my-bucket/object-name

# Download a bucket object to a local file
evroc storage bucket copy --from bucket://my-bucket/object-name --to /path/to/local/file

# Copy between buckets
evroc storage bucket copy --from bucket://source-bucket/object --to bucket://dest-bucket/object
```

### List objects in a bucket

```bash
evroc storage bucket list

# Include deleted versions
evroc storage bucket list --include-deleted

# Include all versions
evroc storage bucket list --include-all
```

### Delete a bucket or objects

```bash
# Delete an empty bucket
evroc storage bucket delete my-bucket

# Delete a non-empty bucket (purges all contents)
evroc storage bucket delete my-bucket --purge

# Skip confirmation
evroc storage bucket delete my-bucket --force --purge

# Delete a specific object
evroc storage bucket delete bucket://my-bucket/example.txt

# Delete all objects but keep the bucket
evroc storage bucket delete bucket://my-bucket/*
```

**Completion criterion:** `evroc storage bucket get <bucket-name>` returns an error (bucket not found) after deletion.

## File Stores (NFS)

### Create a file store

```bash
evroc storage filestore create my-store --zone a
```

### List file stores

```bash
evroc storage filestore list

# With details
evroc storage filestore list -o yaml
```

### Get file store details

```bash
evroc storage filestore get <filestore-name>
```

### Delete a file store

```bash
evroc storage filestore delete my-store

# Skip confirmation
evroc storage filestore delete my-store --force
```

## Bucket Service Accounts

### Create a bucket service account

```bash
evroc storage bucketserviceaccount create my-sa \
  --bucket my-bucket \
  --bucket my-other-bucket
```

### List bucket service accounts

```bash
evroc storage bucketserviceaccount list
```

### Get bucket service account details

```bash
evroc storage bucketserviceaccount get <service-account-name>
```

### Delete a bucket service account

```bash
evroc storage bucketserviceaccount delete my-sa
```

## Pitfalls

- **S3 credentials required for copy**: The `bucket copy` and `bucket list` (within buckets) commands read S3 credentials from `~/.evroc/credentials.ini`. Run `evroc storage bucket get-s3-credentials` first if you haven't already.
- **Bucket must be empty to delete**: A non-empty bucket requires `--purge` to delete. If object locking is enabled, `--purge` is ignored and all versions must be deleted manually first.
- **Object retention modes**: `Disabled` (default), `Suspended`, `Versioned`, `Locking`. Object lock requires the `Locking` mode and needs a default lock mode and duration.
- **File store requires zone**: `--zone` is required for file store creation. The file store uses NFS v4.1.
- **Bucket service accounts**: A service account must reference at least one bucket via `--bucket` (repeatable for multiple buckets).
- **CLI aliases**: `bu` for `bucket`, `fs` for `filestore`, `bsa` for `bucketserviceaccount`, `ls` for `list`, `rm`/`del` for `delete`, `new` for `create`.
