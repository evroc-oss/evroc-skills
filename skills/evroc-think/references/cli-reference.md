# CLI Reference

Full flag reference for `evroc think` commands. All commands inherit `--config string` (path to evroc config file, default `~/.evroc/config.yaml`).

## API Keys

### evroc think apikey create

```
evroc think apikey create <api-key-id> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--expiry-timestamp` | time | Expiry time for the key, in RFC3339 format. |

### evroc think apikey list

```
evroc think apikey list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc think apikey delete

```
evroc think apikey delete <api-key-id> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

## Instances

### evroc think instance create

```
evroc think instance create <instance-id> [flags]
Aliases: create, new
```

| Flag | Type | Description |
|---|---|---|
| `--model` | string | The ID of the Model to serve. |
| `--size` | string | The ID of the instance Size to deploy. |
| `--stopped` | bool | Whether the instance should be created in a stopped state. |

### evroc think instance list

```
evroc think instance list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc think instance get

```
evroc think instance get <instance-id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

### evroc think instance start

```
evroc think instance start <instance-id> [flags]
```

### evroc think instance stop

```
evroc think instance stop <instance-id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

### evroc think instance update

```
evroc think instance update <instance-id> [flags]
Aliases: update, u
```

| Flag | Type | Description |
|---|---|---|
| `--model` | string | The ID of the Model to serve. |
| `--size` | string | The ID of the instance Size to deploy. |
| `--stopped` | bool | Whether the instance should be created in a stopped state. |

### evroc think instance delete

```
evroc think instance delete <instance-id> [flags]
Aliases: delete, del, rm
```

| Flag | Type | Description |
|---|---|---|
| `--force` | bool | Skip interactive prompts. |

## Models

### evroc think model list

```
evroc think model list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

### evroc think model get

```
evroc think model get <model-id> [flags]
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml` (default), `json`, `list`. |

## Shared Models

### evroc think sharedmodel list

```
evroc think sharedmodel list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

## Sizes

### evroc think size list

```
evroc think size list [flags]
Aliases: list, ls
```

| Flag | Type | Description |
|---|---|---|
| `-o, --out` | string | Output: `yaml`, `json`, `list` (default: `list`). |

## Coding Agent Integration

### evroc think code

Launch a coding agent with Think as the model backend. Sets
`OPENAI_API_KEY` and `OPENAI_BASE_URL` for the session and spawns the agent.
An API key is created automatically if you're logged in. A project is created
automatically if you don't have one.

This is a one-off session — no config files are written.

```
evroc think code [flags]
```

Supported agents:

| Subcommand | Agent |
|---|---|
| `evroc think code aider` | Aider |
| `evroc think code claude` | Claude Code |
| `evroc think code codex` | Codex CLI |
| `evroc think code crush` | Crush |
| `evroc think code goose` | Goose |
| `evroc think code hermes` | Hermes Agent |
| `evroc think code openclaw` | OpenClaw |
| `evroc think code opencode` | OpenCode |
| `evroc think code pi` | Pi |
| `evroc think code qwen` | Qwen Code |

### evroc think code hermes

```
evroc think code hermes [flags]
```

| Flag | Type | Description |
|---|---|---|
| `--api-key` | string | Think API key (defaults to `EVROC_API_KEY` env var or auto-created from evroc CLI session). |
| `--model` | string | Model to use (defaults to Kimi-K2.5). |

### evroc think code init

Write permanent config files for a coding agent to use Think. Config files
are written to the project directory and can be committed and shared.

```
evroc think code init [flags]
```

Supported agents:

| Subcommand | Config file written |
|---|---|
| `evroc think code init aider` | `.aider.conf.yml` |
| `evroc think code init claude` | `CLAUDE.md` + `.claude/settings.local.json` |
| `evroc think code init codex` | `~/.codex/config.toml` |
| `evroc think code init continue` | `~/.continue/config.yaml` |
| `evroc think code init crush` | `crush.json` |
| `evroc think code init goose` | `~/.config/goose/config.yaml` |
| `evroc think code init hermes` | `~/.hermes/config.yaml` |
| `evroc think code init openclaw` | `~/.openclaw/openclaw.json` |
| `evroc think code init opencode` | `opencode.jsonc` |
| `evroc think code init pi` | `~/.pi/agent/models.json` |
| `evroc think code init qwen` | `~/.qwen/settings.json` |

See the [evroc Think documentation](https://docs.evroc.com/products/think/index.html) for more details.
