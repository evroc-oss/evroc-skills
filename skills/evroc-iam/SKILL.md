---
name: evroc-iam
description: "Use when the user wants to create, list, inspect, or delete evroc projects; grant or revoke role bindings; manage service accounts and their credentials (including rs256-jwt and hmac-sigv4 credential types); enable or disable service accounts; or retrieve an access token. Requires the evroc CLI. Do NOT trigger for compute, networking, storage, or Think model tasks."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.2"
  category: security
allowed-tools: terminal, read_file
---

# evroc-iam

Manage evroc Identity and Access Management through the `evroc iam` CLI.
Covers projects, role bindings, service accounts, and credentials.

evroc IAM uses a principal-role-permission model: predefined roles (collections of
permissions) are granted to principals (users or service accounts) on a scope
(project or organization).

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, update, or delete a project on evroc
- User wants to grant or revoke roles for a user or service account
- User wants to create or manage service accounts and their credentials
- User wants to enable or disable a service account
- User wants to list available roles or check permissions
- User wants to retrieve an access token for API calls
- User mentions "evroc" with "IAM", "project", "role", "permission", "service account", or "access"

**Do NOT use for:** compute VMs, networking (public IPs, security groups, subnets, VPCs), storage buckets, load balancers, or Think models.

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

## Projects

### List projects

```bash
evroc iam project list
```

### Create a project

```bash
evroc iam project create my-project --name "My Project"
```

**Completion criterion:** `evroc iam project get my-project` returns the project.

### Get project details

```bash
evroc iam project get my-project
```

### Update a project

```bash
evroc iam project update my-project --name "New Name"
```

### Delete a project

HALT: Before running ANY `evroc iam project delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete the Project '<project-name>' and cannot be
undone. Deleting a Project also deletes all associated resources within it
(VMs, disks, networks, load balancers, storage, etc.)."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<project-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc iam project delete my-project --force
```

**Completion criterion:** `evroc iam project get my-project` returns `not found`.

### Set current project

```bash
evroc config set-project my-project
```

## Role Bindings

### List available roles

```bash
evroc iam rolebinding roles
```

Use the role `id` (e.g. `/iam/roles/computeOperator`) when granting.

### Grant a project role

```bash
# To a user
evroc iam rb assign \
  --principal /iam/users/<user-id> \
  --role /iam/roles/projectOwner

# To a service account
evroc iam rb assign \
  --principal /iam/projects/<project-id>/serviceAccounts/<sa-id> \
  --role /iam/roles/storageOperator
```

### Scope a role to specific resources

Limit to specific resource FQIDs with `--resource` (repeatable):

```bash
evroc iam rb assign \
  --principal /iam/users/<user-id> \
  --role /iam/roles/computeOperator \
  --resource /compute/projects/my-project/regions/se-sto/virtualMachines/my-vm
```

Wildcards for one path segment:

```bash
--resource /compute/projects/my-project/regions/se-sto/virtualMachines/*
```

### Grant an organization role

```bash
evroc iam rb assign \
  --principal /iam/users/<user-id> \
  --role /iam/roles/organizationOwner \
  --organization
```

### List role bindings

```bash
# In the current project
evroc iam rb list

# In the current organization
evroc iam rb list --organization

# Your own bindings across all scopes
evroc iam rb list-me
```

### Get a specific role binding

```bash
evroc iam rb get <binding-name>
```

### Revoke a single role

```bash
evroc iam rb revoke \
  --principal /iam/users/<user-id> \
  --role /iam/roles/computeOperator
```

### Delete all roles for a principal

HALT: Before running ANY `evroc iam rb delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete the Role Binding '<binding-name>' and cannot
be undone. This revokes every role for that principal on the selected scope."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<binding-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc iam rb delete <binding-name>
```

This revokes every role for that principal on the selected scope.

### Test permissions via API

```bash
TOKEN=$(evroc iam get-access-token)
curl -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "checks": [
      {
        "permission": "compute.virtualMachines.start",
        "resource": "/compute/projects/my-project/regions/se-sto/virtualMachines/my-vm"
      }
    ]
  }' \
  https://api.evroc.com/iam/v1beta1/testPermissions
```

## Service Accounts

A service account is a non-human identity scoped to a single project. It has no
access of its own until you grant it a role via a role binding (see above).

Service accounts are addressed by fully qualified identifiers (FQIDs):

```
/iam/projects/<project-id>/serviceAccounts/<service-account-id>
```

### Create a service account

```bash
# Enabled by default
evroc iam serviceaccount create my-sa --description "CI/CD automation"

# Create disabled (can't authenticate until enabled)
evroc iam serviceaccount create my-sa --description "CI/CD automation" --enabled=false
```

### List service accounts

```bash
evroc iam serviceaccount list
```

### Get service account details

```bash
evroc iam serviceaccount get my-sa
```

### Enable or disable a service account

A disabled service account cannot authenticate, even if it has credentials and
role bindings.

```bash
# Disable
evroc iam serviceaccount update my-sa --enabled=false

# Re-enable
evroc iam serviceaccount update my-sa --enabled
```

### Credentials

A service account can't authenticate until it has a credential. Credentials come
in two types, each compatible with a different API:

| Type | Key mechanism | Compatible with |
|---|---|---|
| `rs256-jwt` (default) | Asymmetric (RSA + SHA256). Signs a JWT and exchanges it for a short-lived access token via the OAuth 2.0 private key JWT flow. | evroc public API |
| `hmac-sigv4` | Symmetric (HMAC + SHA256). Signs requests with an S3 compatible signature. | S3 compatible API |

Use `rs256-jwt` for managing compute, storage, IAM, or other evroc public API
resources. Use `hmac-sigv4` for reading or writing objects through the S3
compatible API (e.g. with `s3cmd` or `rclone`). If a workload needs both, create
one credential of each type.

#### Create a credential

```bash
# Default type (rs256-jwt), default 1-year expiry
evroc iam serviceaccount credential create cred-1 --service-account my-sa

# 90-day expiry
evroc iam serviceaccount credential create cred-1 --service-account my-sa --expires-in 2160h

# HMAC credential for S3 compatible API
evroc iam serviceaccount credential create cred-1 --service-account my-sa --type hmac-sigv4
```

Credential expiration is mandatory: minimum 24 hours, maximum 2 years. You
can't change the expiration after the credential is created.

For `rs256-jwt` credentials, the access token lifetime is separate from the
credential expiration. The default is 300 seconds (5 minutes), with a minimum of
60 seconds and a maximum of 28800 seconds (8 hours). This is set at credential
creation.

#### List credentials

```bash
evroc iam serviceaccount credential list --service-account my-sa
```

#### Revoke a credential

Revocation invalidates the credential immediately and preserves the audit
record with the reason.

HALT: Before running ANY `evroc iam serviceaccount credential revoke` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently revoke the Credential '<cred-name>' and cannot be
undone. Any services using this credential will immediately lose access."

Then:
1. List the specific resource(s) that will be revoked (credential name, service account, project)
2. Ask the user to confirm: "Type 'yes' to confirm revocation of '<cred-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the revoke command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc iam serviceaccount credential revoke cred-1 --service-account my-sa --reason "Compromised"
```

#### Delete a credential

Delete removes the credential resource entirely. Use revoke if you need an
audit trail.

```bash
evroc iam serviceaccount credential delete cred-1 --service-account my-sa --force
```

### Using a credential

For `rs256-jwt` credentials, the private key (a JSON Web Key) is printed at
creation time. Store it where the workload can read it, e.g. as environment
variables (the evroc Go SDK reads these):

```bash
export EVROC_SERVICE_ACCOUNT_ID="my-sa"
export EVROC_SERVICE_ACCOUNT_SECRET="<private-key>"
```

For `hmac-sigv4` credentials, the access key ID and secret access key are
returned at creation time. Use them to configure your S3 client.

### Delete a service account

HALT: Before running ANY `evroc iam serviceaccount delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete the service account '<sa-name>' and cannot be undone.
Deleting a service account also revokes all associated credentials."

Then:
1. List the specific service account(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<sa-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc iam serviceaccount delete my-sa --force
```

## Access Tokens

```bash
# Get a short-lived bearer token
evroc iam get-access-token

# Get current user info
evroc iam get-user-info
```

## Key Predefined Roles

| Role | Scope | Description |
|---|---|---|
| `/iam/roles/projectOwner` | project | Full control |
| `/iam/roles/projectContributor` | project | Create/manage resources, no access management |
| `/iam/roles/computeOperator` | project | Manage compute resources |
| `/iam/roles/computeViewer` | project | Read-only compute access |
| `/iam/roles/storageOperator` | project | Manage storage buckets |
| `/iam/roles/networkingOperator` | project | Manage networking resources |
| `/iam/roles/thinkOperator` | project | Manage Think instances and API keys |
| `/iam/roles/organizationOwner` | organization | Full org control |
| `/iam/roles/organizationViewer` | organization | Read-only org access |
| `/iam/roles/organizationAccessAdministrator` | organization | Manage role bindings and users |

Run `evroc iam rb roles` for the complete list.

## Pitfalls

- **Private key shown only once**: The private key (JWK for `rs256-jwt`,
  access key ID + secret for `hmac-sigv4`) is returned only at credential
  creation and can't be viewed again. Capture it immediately and store it
  securely.
- **Credential expiry is immutable**: Min 24 hours, max 2 years. You can't
  change the expiration after creation — create a new credential instead.
- **Access token lifetime is separate from credential expiry**: For `rs256-jwt`
  credentials, the short-lived access token expires (default 300s, range
  60s–28800s) and the workload must request a new one. This is independent of
  the credential's own expiration.
- **Service accounts are project-scoped**: A service account belongs to exactly
  one project and its FQID includes that project
  (`/iam/projects/<project-id>/serviceAccounts/<sa-id>`). It can't be shared
  across projects.
- **Revoke vs delete credentials**: Revoke invalidates immediately and keeps
  the audit record (with `--reason`). Delete removes the resource entirely.
  Use revoke for suspected compromise, delete for cleanup.
- **Principals use FQIDs, not emails**: Role bindings reference users by user ID
  (e.g. `/iam/users/5a9bb4ea-...`), not email. Service accounts use
  `/iam/projects/<project-id>/serviceAccounts/<sa-id>`. Find user IDs in the
  evroc Console.
- **Organization roles ≠ project access**: Organization roles govern only org-level
  operations. Grant project roles for access to project resources.
- **Role assignment is idempotent**: Re-running with the same principal+role replaces
  the resource list. Use `--resource` to scope, or omit it for all resources.
- **PermissionSets are deprecated**: Use role bindings. PermissionSets were a binary
  admin model; role bindings provide fine-grained predefined roles.
- **Custom roles not available**: Only predefined roles are supported. Custom roles,
  deny rules, and condition-based bindings are not yet available.
- **Resource name limits**: Max 63 chars, lowercase alphanumeric with hyphens,
  starting/ending alphanumeric.
- **Labeling service accounts**: Service accounts support the `label` subcommand for
  adding/removing labels:
  `evroc iam serviceaccount label <name> --add key=value --remove key`.
  See [`references/cli-reference.md`](references/cli-reference.md) for details.
- **MFA is OTP-only**: TOTP is the only supported MFA mechanism.
- **Brute force protection**: After 10 failed login attempts, the account is locked for
  ~10 minutes with no visual indication.
- **CLI aliases**: `rb` for `rolebinding`, `sa` for `serviceaccount`, `ls` for `list`,
  `rm`/`del` for `delete`, `new` for `create`.
