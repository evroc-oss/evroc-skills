---
name: evroc-storage
description: "Use when the user wants to create, list, inspect, or delete evroc storage resources — S3-compatible buckets, file stores (NFS), or bucket service accounts — or to create, list, rotate, import, suspend, or delete evroc KMS keys. Requires the evroc CLI. Do NOT trigger for compute VMs, IAM, networking, load balancers, or Think models."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.6"
  category: infrastructure
allowed-tools: terminal, read_file
---

# evroc-storage

Manage evroc storage resources through the `evroc storage` CLI. Covers S3-compatible
buckets, file stores (NFS), and bucket service accounts. Also covers evroc KMS
(key management) through the `evroc kms` CLI.

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, or delete an S3-compatible bucket
- User wants to copy files to or from a bucket
- User wants to get S3 credentials for programmatic access
- User wants to create a bucket service account for bucket access
- User wants to create a file store (NFS)
- User wants to create, list, rotate, import, suspend, or delete KMS keys
- User mentions "evroc" with "bucket", "storage", "S3", "file store", "object storage", "KMS", or "encryption key"

**Do NOT use for:** compute VMs, networking (public IPs, security groups, subnets, VPCs), IAM, load balancers, or Think models.

## Prerequisites

Ensure the evroc CLI is installed:

```bash
bash scripts/check-cli.sh
```

CLI upgrade confirmation: `check-cli.sh` also runs `evroc upgrade --dry-run` and
prints "UPGRADE AVAILABLE" when a newer CLI release exists. Upgrading replaces
the binary mid-session, so it requires explicit user consent.

HALT: If check-cli.sh (or any command output) reports "UPGRADE AVAILABLE", you MUST:

1. Show the user the dry-run report (current release, newer release, install path)
2. Ask: "Upgrade the evroc CLI now? Type 'yes' to confirm."
3. Wait for the user to explicitly type 'yes'

Only then run `evroc upgrade` (it verifies checksums, backs up the previous
binary, and rolls back automatically if the new binary fails its self-test).
Do NOT run `evroc upgrade` without explicit confirmation.
A silence or ambiguous response is NOT confirmation.
If the user declines, continue with the current CLI version.

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

# Credentials valid for 12 hours (default 1h, range 15m to 12h)
evroc storage bucket get-s3-credentials --duration 12h
```

Credentials are written to `~/.evroc/credentials.ini` by default. They are
valid for 1 hour by default — request a different lifetime with `--duration`
(minimum 15 minutes, maximum 12 hours). Auto-rotating S3 clients pick up new
credentials on expiry; re-run the command manually if a long-lived credential
is about to lapse mid-operation.

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

## KMS (Key Management Service)

Manage encryption keys through `evroc kms keys`: create, list, get, rotate,
import, suspend/activate, trim, and delete.

### List keys

```bash
evroc kms keys list
evroc kms keys list -l "team in (frontend,backend)"
```

### Get key details

```bash
evroc kms keys get <key-id> -o yaml
```

### Create a key

```bash
# Default algorithm (aes256-gcm96)
evroc kms keys create my-key

# Auto-rotate the key version every 90 days
evroc kms keys create my-key --auto-rotate-days=90

# Expire key versions after 365 days
evroc kms keys create my-key --expiration-days=365
```

### Rotate a key

```bash
evroc kms keys rotate my-key
```

A new key version is generated and becomes the default for future use.
Previous versions remain valid until trimmed.

### Imported keys (bring your own key material)

```bash
# 1. Create a key pending import, then provide the material from a local file
evroc kms keys create my-key --imported
evroc kms keys import my-key --path /path/to/key-material

# 2. Rotate an imported key by importing new material
evroc kms keys import-rotate my-key --path /path/to/new-material
```

The key material is wrapped locally with an ephemeral data key before anything
is sent to the KMS — the plaintext material never leaves the machine.

### Suspend / activate a key

```bash
# Suspends the key from being used (reversible)
evroc kms keys suspend my-key

# Re-activates a suspended (or pre-activated) key
evroc kms keys activate my-key
```

### Trim versions

HALT: Before running ANY `evroc kms keys trim` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently trim all key versions below the minimum version to
keep of Key '<key-id>' and cannot be undone. Data encrypted with trimmed
versions will no longer be decryptable."

Then:
1. List the key and its versions (`evroc kms keys get <key-id> -o yaml`)
2. Ask the user to confirm: "Type 'yes' to confirm trimming of key '<key-id>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the trim command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
# Keep versions >= 3; lower versions are suspended and later purged
evroc kms keys trim my-key --min-version-to-keep 3

# Abort while versions are pending final trim (re-activates them)
evroc kms keys trim-abort my-key
```

It is not possible to trim the latest/current version.

### Delete a key

HALT: Before running ANY `evroc kms keys delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete the Key '<key-id>' and cannot be undone.
Data encrypted with this key will become permanently undecryptable after
the grace period passes."

Then:
1. List the specific resource(s) that will be deleted (key ID, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<key-id>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc kms keys delete my-key --force

# Abort deletion while the key is pending deletion (restores the key)
evroc kms keys delete-abort my-key
```

**Completion criterion:** `evroc kms keys get my-key` shows the key in
"Pending Deletion" state (or `not found` after the grace period passes).

## Quota errors (InsufficientQuota)

Object storage is limited by a PROJECT quota (`spec.objectStorage.totalSize`), unlike other services which use org quotas. Writes beyond the total size limit fail — the S3 proxy returns `QuotaExceeded` on object PUTs, and bucket/file store limits reject with HTTP 403 containing `reason: "InsufficientQuota"` and the text `not enough quota to perform request`.

IMPORTANT: the quota API does not report current object-storage usage — `evroc quotas projectquotas get` returns an empty `status` (the CLI table shows "Current: -"). `check-quota.sh` therefore shows the limit only and cannot verify whether N GB fit; the S3 proxy enforces the real total at write time.

HALT: When a bucket write fails with `QuotaExceeded` or a `create` command fails
with HTTP 403 and a body containing "InsufficientQuota" (or the text
"not enough quota to perform request"), you MUST:

1. Run: `bash scripts/check-quota.sh size` (or `evroc quotas projectquotas get`)
   — note: project quota, not `evroc quotas orgquotas get`
2. Report to the user VERBATIM: the project object storage limit (usage is not
   exposed by the API) — e.g. "Object Storage limit: 10TB (usage not reported)"
3. State: "To request a quota increase, contact support@evroc.com"
4. Do NOT retry the write or attempt workarounds until the user decides (delete
   unneeded objects/buckets, or contact support). A silence or ambiguous
   response is NOT confirmation to retry.

## Pitfalls

- **CLI upgrade, never silent**: `evroc upgrade` replaces the CLI binary. `check-cli.sh` reports
  "UPGRADE AVAILABLE" via `evroc upgrade --dry-run` — the agent must ask the user and receive an
  explicit 'yes' before running `evroc upgrade` (see Prerequisites HALT). Version flag trap:
  the CLI reports its version with the `evroc version` subcommand (this always exists);
  `evroc --version` and `evroc -v` do NOT exist on the CLI root. The only valid `--version` flag is
  on the upgrade subcommand — `evroc upgrade --version <release-name>` installs exactly that named
  published release (e.g. `--version 20261019-1792428909-root-3d363240`).
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
- **Object storage quota is project-scoped**: Check the limit with
  `evroc quotas projectquotas get` (hidden but works) or
  `bash scripts/check-quota.sh size`. Usage is NOT reported by the quota API
  (empty `status`), so the script shows the limit only. S3 PUTs beyond the
  limit fail with `QuotaExceeded`. To request an increase, contact
  support@evroc.com.
- **CLI aliases**: `bu` for `bucket`, `fs` for `filestore`, `bsa` for
  `bucketserviceaccount`, `ls` for `list`, `rm`/`del` for `delete`, `new` for `create`.
- **KMS delete is two-phase and recoverable only during the grace period**:
  `evroc kms keys delete` moves the key to "Pending Deletion" (not usable for
  encrypt/decrypt); after a grace period it is permanently deleted and cannot
  be restored. Run `evroc kms keys delete-abort <key-id>` to recover a key
  that is still pending deletion.
- **KMS trim is two-phase too**: trimmed versions are suspended immediately
  and permanently purged after a grace period — `trim-abort` re-activates
  versions still pending final trim. The latest/current version can never be
  trimmed. Gate trims with a HALT confirmation (destructive).
- **Imported keys rotate differently**: a key created with `--imported` is
  rotated by `evroc kms keys import-rotate` (new material), NOT `rotate`.
  `import` fails unless the key was created with `--imported`.
- **Suspend is reversible, delete is not**: a suspended key is re-activated
  with `evroc kms keys activate`. There is no equivalent recovery once a key
  has been past its deletion grace period.
- **KMS defaults**: algorithm `aes256-gcm96`; `--auto-rotate-days` and
  `--expiration-days` default to `-1` (disabled) unless set explicitly.
