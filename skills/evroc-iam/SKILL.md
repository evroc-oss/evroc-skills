---
name: evroc-iam
description: "Manage evroc IAM resources: projects, role bindings, service accounts, and credentials via the evroc CLI. Use when the user wants to create projects, grant or revoke roles, manage service accounts, or inspect permissions on evroc cloud."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.0"
  category: infrastructure
allowed-tools: terminal
---

# evroc-iam

Manage evroc Identity and Access Management through the `evroc iam` CLI. Covers
projects, role bindings, service accounts, and credentials. evroc IAM uses a
principal-role-permission model: you grant predefined roles (collections of
permissions) to principals (users or service accounts) on a scope (project or
organization).

For full CLI flag reference, read [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, update, or delete a project on evroc
- User wants to grant or revoke roles for a user or service account
- User wants to create or manage service accounts and their credentials
- User wants to list available roles or check permissions
- User wants to retrieve an access token for API calls
- User mentions "evroc" with "IAM", "project", "role", "permission", "service account", or "access"

## Prerequisites

The evroc CLI must be installed and authenticated:

```bash
evroc login
```

Verify auth:

```bash
cat ~/.evroc/config.yaml
```

## Projects

Projects are isolated containers for cloud resources with their own access
controls and quota tracking.

### List projects

```bash
evroc iam project list
```

### Create a project

```bash
evroc iam project create my-project --name "My Project"
```

- `<project_id>` — Required. Lowercase alphanumeric with hyphens, max 63 chars.
- `--name` — Optional display name. Defaults to the project ID.

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
evroc iam project delete my-project

# Skip confirmation
evroc iam project delete my-project --force
```

**Completion criterion:** `evroc iam project get my-project` returns an error (not found).

### Set current project

```bash
evroc config set-project my-project
```

All subsequent CLI commands operate on this project until you switch.

## Role Bindings

Role bindings grant predefined roles to principals (users or service accounts)
on a project or organization scope. Roles are additive — a principal with
multiple roles receives the union of all permissions.

### List available roles

```bash
evroc iam rolebinding roles

# Shortcut
evroc iam rb roles
```

Use the role `id` value (e.g. `/iam/roles/computeOperator`) when granting access.

### Grant a project role

```bash
evroc config set-project my-project
evroc iam rb assign \
  --principal /iam/users/<user-id> \
  --role /iam/roles/projectOwner
```

### Grant access to specific resources only

Limit a role to specific resource FQIDs with `--resource` (repeatable):

```bash
evroc iam rb assign \
  --principal /iam/users/<user-id> \
  --role /iam/roles/computeOperator \
  --resource /compute/projects/my-project/regions/se-sto/virtualMachines/my-vm
```

Use `*` as a wildcard for a single path segment:

```bash
# All VMs in one region
--resource /compute/projects/my-project/regions/se-sto/virtualMachines/*
```

### Grant an organization role

```bash
evroc iam rb assign \
  --principal /iam/users/<user-id> \
  --role /iam/roles/organizationOwner \
  --organization
```

Organization roles govern org-level IAM operations only. They don't grant
access to resources inside projects.

### List role bindings

```bash
# In the current project
evroc iam rb list

# In the current organization
evroc iam rb list --organization

# Your own role bindings across all scopes
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

This revokes every role in the binding for that principal on the selected scope.

### Test permissions via API

```bash
TOKEN=$(evroc iam get-access-token)
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
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

Service accounts are identities for automation. Grant roles to service
accounts the same way as users — use the service account FQID as the principal.

### Create a service account

```bash
evroc iam serviceaccount create my-sa --description "CI/CD automation"
```

- `--enabled` — Enable or disable (default: true).
- `--description` — Human-readable description.

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

### Get an access token

```bash
evroc iam get-access-token
```

Returns a short-lived bearer token for authenticating against evroc APIs.

### Get current user info

```bash
evroc iam get-user-info
```

## Key Predefined Roles

| Role | Scope | Description |
|---|---|---|
| `/iam/roles/projectOwner` | project | Full control over a project |
| `/iam/roles/projectContributor` | project | Create/manage resources, no access management |
| `/iam/roles/computeOperator` | project | Create/manage compute resources |
| `/iam/roles/computeViewer` | project | Read-only compute access |
| `/iam/roles/storageOperator` | project | Manage storage buckets and contents |
| `/iam/roles/networkingOperator` | project | Manage networking resources |
| `/iam/roles/thinkOperator` | project | Manage Think instances and API keys |
| `/iam/roles/organizationOwner` | organization | Full org control |
| `/iam/roles/organizationViewer` | organization | Read-only org access |
| `/iam/roles/organizationAccessAdministrator` | organization | Manage role bindings and users |

Use `evroc iam rb roles` for the complete list with permissions.

## Pitfalls

- **Principals use FQIDs, not emails**: Role bindings reference users by their
  user ID (e.g. `/iam/users/5a9bb4ea-...`), not by email address. Find user IDs
  in the evroc Console → Users Management section.
- **Organization roles don't grant project access**: Organization roles govern
  org-level operations only. Grant project roles for access to resources inside
  projects.
- **Role assignment is idempotent**: If the principal already has the role,
  the request replaces the role's resource list. Pass `--resource` to scope,
  or omit it to grant on all applicable resources.
- **PermissionSets are deprecated**: Use role bindings instead. PermissionSets
  were a binary admin/not-admin model; role bindings provide fine-grained
  predefined roles with resource-level scoping.
- **Custom roles not available**: Only predefined roles are supported. Custom
  roles, deny rules, and condition-based bindings are not yet available.
- **Resource name limits**: All resource names are capped at 63 characters,
  lowercase alphanumeric with hyphens, starting and ending with an alphanumeric
  character.
- **MFA is OTP-only**: IAM supports time-based one-time password (TOTP) as the
  only MFA mechanism.
- **Brute force protection**: After 10 failed login attempts, the account is
  temporarily locked with no visual indication. Wait 10 minutes before
  retrying.
- **CLI aliases**: `rb` for `rolebinding`, `sa` for `serviceaccount`, `ls` for
  `list`, `rm`/`del` for `delete`, `new` for `create`.
