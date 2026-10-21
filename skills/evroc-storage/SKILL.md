---
name: evroc-storage
description: "Use when the user wants to create, list, inspect, or delete evroc storage resources — S3-compatible buckets, file stores (NFS), or bucket service accounts. Requires the evroc CLI. Do NOT trigger for compute VMs, IAM, networking, load balancers, or Think models."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.3"
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

HALT: Before running ANY `evroc storage bucket delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete your Bucket '<bucket-name>' and cannot be
undone."
If using `--purge`, also output: "All objects within the bucket will also
be deleted."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<bucket-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

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

HALT: Before running ANY `evroc storage filestore delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete your File Store '<filestore-name>' and cannot
be undone."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<filestore-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

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

HALT: Before running ANY `evroc storage bucketserviceaccount delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete your Bucket Service Account '<sa-name>' and
cannot be undone."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<sa-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc storage bucketserviceaccount delete my-sa --force
```

## Quota errors (InsufficientQuota)

Object storage is limited by a PROJECT quota (`spec.objectStorage.totalSize`), unlike other services which use org quotas. Writes beyond the total size limit fail — the S3 proxy returns `QuotaExceeded` on object PUTs, and bucket/file store limits reject with HTTP 403 containing `reason: "InsufficientQuota"` and the text `not enough quota to perform request`.

HALT: When a bucket write fails with `QuotaExceeded` or a `create` command fails
with HTTP 403 and a body containing "InsufficientQuota" (or the text
"not enough quota to perform request"), you MUST:

1. Run: `bash scripts/check-quota.sh size` (or `evroc quotas projectquotas get`)
   — note: project quota, not `evroc quotas orgquotas get`
2. Report to the user VERBATIM: current object storage usage and limit — e.g.
   "Object Storage: 10TB/10TB used — at limit"
3. State: "To request a quota increase, contact support@evroc.com"
4. Do NOT retry the write or attempt workarounds until the user decides (delete
   unneeded objects/buckets, or contact support). A silence or ambiguous
   response is NOT confirmation to retry.

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
- **Object storage quota is project-scoped**: Check real usage with
  `evroc quotas projectquotas get` (hidden but works) or
  `bash scripts/check-quota.sh size`. S3 PUTs beyond the limit fail with
  `QuotaExceeded`. To request an increase, contact support@evroc.com.
- **CLI aliases**: `bu` for `bucket`, `fs` for `filestore`, `bsa` for
  `bucketserviceaccount`, `ls` for `list`, `rm`/`del` for `delete`, `new` for `create`.
