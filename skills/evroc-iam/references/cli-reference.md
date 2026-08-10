# CLI Reference

Full flag reference for `evroc iam` commands. All commands inherit `--config string` (path to evroc config file, default `~/.evroc/config.yaml`).

## Projects

### evroc iam project create

```
evroc iam project create <project_id> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--name` | string | Name (defaults to id if empty) |

### evroc iam project list

```
evroc iam project list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-a, --all` | bool | Include all accessible projects |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc iam project get

```
evroc iam project get <project_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc iam project update

```
evroc iam project update <project_id> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--name` | string | Name (defaults to id if empty) |

### evroc iam project delete

```
evroc iam project delete <project_id> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

## Role Bindings

### evroc iam rolebinding assign

```
evroc iam rolebinding assign [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--organization` | bool | Assign in the current organization instead of project. |
| `--principal` | string | Principal FQID (e.g. `/iam/users/<user-id>`). |
| `--resource` | strings | Optional resource FQIDs to scope the role to. Repeatable. |
| `--role` | string | Role FQID (e.g. `/iam/roles/organizationViewer`). |

### evroc iam rolebinding revoke

```
evroc iam rolebinding revoke [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--organization` | bool | Revoke in the current organization instead of project. |
| `--principal` | string | Principal FQID (e.g. `/iam/users/<user-id>`). |
| `--role` | string | Role FQID (e.g. `/iam/roles/<role>`). |

### evroc iam rolebinding list

```
evroc iam rolebinding list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `--organization` | bool | List organization-scoped rolebindings. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc iam rolebinding list-me

```
evroc iam rolebinding list-me [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc iam rolebinding get

```
evroc iam rolebinding get <rolebinding_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--organization` | bool | Get an organization-scoped rolebinding. |
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc iam rolebinding delete

```
evroc iam rolebinding delete <rolebinding_id> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |
| `--organization` | bool | Delete an organization-scoped rolebinding. |

### evroc iam rolebinding roles

```
evroc iam rolebinding roles [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

## Service Accounts

### evroc iam serviceaccount create

```
evroc iam serviceaccount create <serviceaccount_id> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--description` | string | Description. |
| `--enabled` | bool | Enable the serviceaccount (default: true). |

### evroc iam serviceaccount list

```
evroc iam serviceaccount list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-l, --label-selector` | string | Kubernetes-style label selector. |
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc iam serviceaccount get

```
evroc iam serviceaccount get <serviceaccount_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc iam serviceaccount update

```
evroc iam serviceaccount update <serviceaccount_id> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--description` | string | Description. |
| `--enabled` | bool | Enable or disable the serviceaccount. |

### evroc iam serviceaccount label

```
evroc iam serviceaccount label [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-a, --add` | stringToString | Label to add (default `[]`). |
| `-r, --remove` | strings | Label to remove. Repeatable. |

### evroc iam serviceaccount delete

```
evroc iam serviceaccount delete <serviceaccount_id> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

## Service Account Credentials

### evroc iam serviceaccount credential create

```
evroc iam serviceaccount credential create <credential_id> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--expires-in` | duration | Duration until expiry (default: `8760h` = 1 year). |
| `--service-account` | string | Service account ID (required). |
| `--type` | string | Credential type (default: `rs256-jwt`). |

### evroc iam serviceaccount credential list

```
evroc iam serviceaccount credential list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |
| `--service-account` | string | Service account ID (required). |

### evroc iam serviceaccount credential get

```
evroc iam serviceaccount credential get <credential_id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |
| `--service-account` | string | Service account ID (required). |

### evroc iam serviceaccount credential revoke

```
evroc iam serviceaccount credential revoke <credential_id> [flags]
Aliases: revoke, rev
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |
| `--reason` | string | Reason for revocation (required). |
| `--service-account` | string | Service account ID (required). |

### evroc iam serviceaccount credential delete

```
evroc iam serviceaccount credential delete <credential_id> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |
| `--service-account` | string | Service account ID (required). |

## Tokens and User Info

### evroc iam get-access-token

```
evroc iam get-access-token [flags]
```

Returns a short-lived Bearer token for authenticating against evroc APIs. The
token expires after a few minutes.

### evroc iam get-user-info

```
evroc iam get-user-info [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

## Predefined Roles

20 predefined roles across project and organization scopes. Use `evroc iam rb
roles` for the full list with permissions.

| Role ID | Scope | Permissions |
|---|---|---|
| `/iam/roles/projectOwner` | project | 141 |
| `/iam/roles/projectContributor` | project | 135 |
| `/iam/roles/projectAccessAdministrator` | project | 19 |
| `/iam/roles/computeOperator` | project | 27 |
| `/iam/roles/computeViewer` | project | 11 |
| `/iam/roles/storageOperator` | project | 28 |
| `/iam/roles/networkingOperator` | project | 25 |
| `/iam/roles/networkingUser` | project | 3 |
| `/iam/roles/networkingViewer` | project | 9 |
| `/iam/roles/loadBalancerOperator` | project | 21 |
| `/iam/roles/loadBalancerViewer` | project | 9 |
| `/iam/roles/thinkOperator` | project | 23 |
| `/iam/roles/thinkViewer` | project | 13 |
| `/iam/roles/securityIncidentResponder` | project | 31 |
| `/iam/roles/quotaViewer` | project | 4 |
| `/iam/roles/cicdInfrastructureManager` | project | 43 |
| `/iam/roles/organizationOwner` | organization | 23 |
| `/iam/roles/organizationViewer` | organization | 7 |
| `/iam/roles/organizationProjectCreator` | organization | 7 |
| `/iam/roles/organizationAccessAdministrator` | organization | 19 |

See the [evroc IAM permissions reference](https://docs.evroc.com/products/iam/concepts/permissions.html) for the authoritative list.
