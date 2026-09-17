---
name: evroc-storage
description: "Use when the user wants to create, list, inspect, or delete evroc storage resources — S3-compatible buckets, file stores (NFS), or bucket service accounts. Requires the evroc CLI. Do NOT trigger for compute VMs, IAM, networking, load balancers, or Think models."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.2"
  category: infrastructure
allowed-tools: terminal, read_file
---

# evroc-storage

Manage evroc storage resources through the `evroc storage` CLI. Covers S3-compatible
buckets, file stores (NFS), and bucket service accounts.

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, or delete an S3-compatible bucket
- User wants to copy files to or from a bucket
- User wants to get S3 credentials for programmatic access
- User wants to create or manage a file store (NFS)
- User wants to create a bucket service account for bucket access
- User mentions "evroc" with "bucket", "storage", "S3", "file store", or "object storage"

**Do NOT use for:** compute VMs, networking (public IPs, security groups, subnets, VPCs), IAM, load balancers, or Think models.

## Prerequisites

Ensure the evroc CLI is installed:

```bash
bash scripts/check-cli.sh
```

Then authenticate:

```bash
bash scripts/check-auth.sh
```

If it fails:

```bash
evroc login
```

## Object Storage (Buckets)

### List buckets

```bash
evroc storage bucket list

evroc storage bucket list -o yaml
evroc storage bucket list -l "environment=production"
```

### Get bucket details

```bash
evroc storage bucket get <bucket-name> -o yaml
```

### Create a bucket

```bash
# Simple
evroc storage bucket create my-bucket

# With object versioning
evroc storage bucket create my-bucket --object-retention-mode=Versioned

# With object locking
evroc storage bucket create my-bucket \
  --object-retention-mode=Locking \
  --default-object-lock-mode=Soft \
  --default-object-lock-duration-days=30

# With a lifecycle policy
evroc storage bucket create my-bucket \
  --lifecycle-policy=file://lifecycle-policy.json
```

### Get S3 credentials

Before copying objects or using S3 clients, retrieve credentials:

```bash
evroc storage bucket get-s3-credentials

# Custom path
evroc storage bucket get-s3-credentials --path /tmp/s3-creds.ini
```

Credentials are written to `~/.evroc/credentials.ini` by default.

### Copy objects

```bash
# Upload
evroc storage bucket copy --from /path/to/local/file --to bucket://my-bucket/object-name

# Download
evroc storage bucket copy --from bucket://my-bucket/object-name --to /path/to/local/file

# Between buckets
evroc storage bucket copy \
  --from bucket://source-bucket/object \
  --to bucket://dest-bucket/object
```

### List objects

```bash
# Current objects
evroc storage bucket list

# Include deleted versions
evroc storage bucket list --include-deleted

# Include all versions
evroc storage bucket list --include-all
```

### Delete a bucket or objects

> ⚠️ **DESTRUCTIVE ACTION — EXPLICIT USER CONFIRMATION REQUIRED**
>
> Before running this command, you MUST:
> 1. Present the user with the resource(s) that will be deleted, including the
>    resource name and type
> 2. State the destruction warning:
>    "This will permanently delete your Bucket and cannot be undone."
>    If using `--purge`, append: "All objects within the bucket will also be deleted."
> 3. Wait for the user to explicitly confirm before proceeding
>
> Do NOT run the delete command until the user responds with explicit confirmation.

```bash
# Empty bucket
evroc storage bucket delete my-bucket --force

# Non-empty bucket (purges all contents)
evroc storage bucket delete my-bucket --purge --force

# Specific object
evroc storage bucket delete bucket://my-bucket/example.txt

# All objects, keep bucket
evroc storage bucket delete bucket://my-bucket/* --force
```

**Completion criterion:** `evroc storage bucket get my-bucket` returns `not found`.

## File Stores (NFS)

### Create a file store

```bash
evroc storage filestore create my-store --zone a
```

### List file stores

```bash
evroc storage filestore list
evroc storage filestore list -o yaml
```

### Get file store details

```bash
evroc storage filestore get <filestore-name> -o yaml
```

### Delete a file store

> ⚠️ **DESTRUCTIVE ACTION — EXPLICIT USER CONFIRMATION REQUIRED**
>
> Before running this command, you MUST:
> 1. Present the user with the resource(s) that will be deleted, including the
>    resource name and type
> 2. State the destruction warning:
>    "This will permanently delete your File Store and cannot be undone."
> 3. Wait for the user to explicitly confirm before proceeding
>
> Do NOT run the delete command until the user responds with explicit confirmation.

```bash
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

### Get details

```bash
evroc storage bucketserviceaccount get <service-account-name>
```

### Delete

> ⚠️ **DESTRUCTIVE ACTION — EXPLICIT USER CONFIRMATION REQUIRED**
>
> Before running this command, you MUST:
> 1. Present the user with the resource(s) that will be deleted, including the
>    resource name and type
> 2. State the destruction warning:
>    "This will permanently delete your Bucket Service Account and cannot be undone."
> 3. Wait for the user to explicitly confirm before proceeding
>
> Do NOT run the delete command until the user responds with explicit confirmation.

```bash
evroc storage bucketserviceaccount delete my-sa --force
```

## Pitfalls

- **S3 credentials required for copy**: `bucket copy` and `bucket list` (within buckets)
  read S3 credentials from `~/.evroc/credentials.ini`. Run
  `evroc storage bucket get-s3-credentials` first if you haven't already.
- **Bucket must be empty to delete**: Non-empty buckets require `--purge` to delete.
  If object locking is enabled, `--purge` is ignored — delete all versions first.
- **Object retention modes**: `Disabled` (default), `Suspended`, `Versioned`, `Locking`.
  Object lock requires `Locking` mode and a default lock mode+duration.
- **File store requires zone**: `--zone` is required for file store creation.
  The file store uses NFS v4.1.
- **Bucket service accounts**: Must reference at least one bucket via `--bucket`
  (repeatable for multiple buckets).
- **Labeling**: Buckets, file stores, and bucket service accounts support the `label`
  subcommand for adding/removing labels:
  `evroc storage <resource> label <name> --add key=value --remove key`.
  See [`references/cli-reference.md`](references/cli-reference.md) for details.
- **CLI aliases**: `bu` for `bucket`, `fs` for `filestore`, `bsa` for
  `bucketserviceaccount`, `ls` for `list`, `rm`/`del` for `delete`, `new` for `create`.
