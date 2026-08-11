---
name: evroc-iam
description: "Use when the user wants to create, list, inspect, or delete evroc projects; grant or revoke role bindings; manage service accounts and their credentials; or retrieve an access token. Requires the evroc CLI. Do NOT trigger for compute, networking, storage, or Think model tasks."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.1"
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
- User wants to list available roles or check permissions
- User wants to retrieve an access token for API calls
- User mentions "evroc" with "IAM", "project", "role", "permission", "service account", or "access"

**Do NOT use for:** compute VMs, networking, storage buckets, load balancers, or Think models.

## Prerequisites

Run the auth check first:

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

```bash
evroc iam project delete my-project -f
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
evroc iam rb assign \
  --principal /iam/users/<user-id> \
  --role /iam/roles/projectOwner
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

### Create a service account

```bash
evroc iam serviceaccount create my-sa --description "CI/CD automation"
```

### List service accounts

```bash
evroc iam serviceaccount list
```

### Get service account details

```bash
evroc iam serviceaccount get my-sa
```

### Create a credential

```bash
# Default 1-year expiry
evroc iam serviceaccount credential create cred-1 --service-account my-sa

# 90-day expiry
evroc iam serviceaccount credential create cred-1 --service-account my-sa --expires-in 2160h
```

### List credentials

```bash
evroc iam serviceaccount credential list --service-account my-sa
```

### Revoke a credential

```bash
evroc iam serviceaccount credential revoke cred-1 --service-account my-sa
```

### Delete a service account

```bash
evroc iam serviceaccount delete my-sa
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

- **Principals use FQIDs, not emails**: Role bindings reference users by user ID
  (e.g. `/iam/users/5a9bb4ea-...`), not email. Find user IDs in the evroc Console.
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
- **MFA is OTP-only**: TOTP is the only supported MFA mechanism.
- **Brute force protection**: After 10 failed login attempts, the account is locked for
  ~10 minutes with no visual indication.
- **CLI aliases**: `rb` for `rolebinding`, `sa` for `serviceaccount`, `ls` for `list`,
  `rm`/`del` for `delete`, `new` for `create`.
