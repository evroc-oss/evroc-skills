---
name: evroc-think
description: "Manage evroc Think Models: deploy dedicated model instances, use shared models, create API keys, list available models and sizes, and launch coding agents with Think as backend via the evroc CLI."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.0"
  category: ai
allowed-tools: terminal
---

# evroc-think

Manage evroc Think Models — a Model-as-a-Service inference platform hosting
leading open-source AI models on NVIDIA H100 and B200 GPUs. Deploy dedicated
model instances or use shared model endpoints with OpenAI-compatible APIs.

For full CLI flag reference, read [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, start, stop, or delete a model instance
- User wants to list available models or instance sizes
- User wants to list or use shared models
- User wants to create or manage API keys for Think endpoints
- User wants to launch a coding agent (Claude Code, Codex, Hermes, etc.) with Think as backend
- User mentions "evroc" with "Think", "model", "inference", "GPU", "LLM", or "AI model"

## Prerequisites

The evroc CLI must be installed and authenticated:

```bash
evroc login
```

Verify auth:

```bash
cat ~/.evroc/config.yaml
```

## Shared Models

Shared Models are managed by evroc — no deployment needed. All shared models
have OpenAI API-compatible endpoints.

### List shared models

```bash
evroc think sharedmodel list
```

### Use a shared model

Shared models expose OpenAI-compatible endpoints. Create an API key (see
below), then call the endpoint:

```bash
curl -H "Authorization: Bearer $THINK_API_KEY" \
  https://models.think.evroc.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<shared-model-id>",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## Dedicated Model Instances

Dedicated instances give you a single model on isolated GPU resources. Each
GPU resource is used by at most one model instance.

### List available models

```bash
evroc think model list

# With full details
evroc think model list -o yaml
```

### Get model details

```bash
evroc think model get <model-id>
```

### List available instance sizes

```bash
evroc think size list
```

Sizes specify GPU resources, e.g. `1-b200-27c-240g` (1× B200 GPU, 27 vCPUs, 240GB RAM).

### Create a dedicated instance

```bash
evroc think instance create my-instance \
  --model mistralai/Ministral-8B-Instruct-2410 \
  --size 1-b200-27c-240g
```

- `<instance-id>` — Required. Lowercase alphanumeric with hyphens, max 63 chars.
- `--model` — Required. HuggingFace model handle (e.g. `mistralai/Ministral-8B-Instruct-2410`).
- `--size` — Required. Instance size ID from `evroc think size list`.
- `--stopped` — Create in stopped state (default: running).

**Completion criterion:** `evroc think instance get my-instance` returns the instance with status showing it exists.

### List instances

```bash
evroc think instance list
```

### Get instance details

```bash
evroc think instance get my-instance
```

### Start an instance

```bash
evroc think instance start my-instance
```

### Stop an instance

```bash
evroc think instance stop my-instance
```

### Update an instance

```bash
evroc think instance update my-instance --model <new-model-id>
```

### Delete an instance

```bash
evroc think instance delete my-instance

# Skip confirmation
evroc think instance delete my-instance --force
```

**Completion criterion:** `evroc think instance get my-instance` returns an error (not found).

## API Keys

API keys authenticate requests to Think model endpoints (both shared and
dedicated). Create keys via the CLI and use them as Bearer tokens.

### Create an API key

```bash
evroc think apikey create my-key

# With expiry timestamp (RFC3339)
evroc think apikey create my-key --expiry-timestamp 2026-12-31T23:59:59Z
```

### List API keys

```bash
evroc think apikey list
```

### Delete an API key

```bash
evroc think apikey delete my-key
```

## Coding Agent Integration

Think can serve as the model backend for coding agents. Two modes:

### One-off session (no config files written)

```bash
# Launch Claude Code with Think
evroc think code claude

# Launch Codex with Think
evroc think code codex

# Launch Hermes Agent with Think
evroc think code hermes

# Launch OpenCode with Think
evroc think code opencode

# Launch Aider with Think
evroc think code aider
```

This sets `OPENAI_API_KEY` and `OPENAI_BASE_URL` for the session and spawns
the agent. An API key is created automatically if you're logged in. A project
is created automatically if you don't have one.

### Permanent project config (committable)

Write agent-specific config files into your project directory:

```bash
# Claude Code → CLAUDE.md + .claude/settings.local.json
evroc think code init claude

# Codex → ~/.codex/config.toml
evroc think code init codex

# Hermes Agent → ~/.hermes/config.yaml
evroc think code init hermes

# OpenCode → opencode.jsonc
evroc think code init opencode
```

Config files can be committed and shared with your team.

## Inference API

Think exposes an OpenAI-compatible API at `https://models.think.evroc.com/v1`.
Use any OpenAI-compatible client:

```bash
TOKEN=$(evroc think apikey create temp-key)
curl -H "Authorization: Bearer $TOKEN" \
  https://models.think.evroc.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model-id>",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

List available models via the API:

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  https://models.think.evroc.com/v1/models | python3 -c \
  "import sys,json; [print(m['id']) for m in json.load(sys.stdin)['data']]"
```

## Pitfalls

- **Dedicated vs shared**: Shared models are ready-to-use with no deployment.
  Dedicated instances require you to choose a model and size, then wait for
  deployment. Use shared models for quick access; dedicated instances for
  isolation and custom configurations.
- **Model IDs are HuggingFace handles**: The `--model` flag uses HuggingFace
  format (e.g. `mistralai/Ministral-8B-Instruct-2410`), not a custom name.
- **Size format**: Instance sizes encode GPU type and resources, e.g.
  `1-b200-27c-240g` = 1× B200 GPU, 27 vCPUs, 240GB RAM. Run `evroc think size
  list` for the authoritative list.
- **API key expiry**: API keys created without `--expiry-timestamp` have no
  expiry. Set an expiry for short-lived access.
- **Code integration auto-creates resources**: `evroc think code` and
  `evroc think code init` automatically create an API key and project if you
  don't have one. Check `evroc think apikey list` after to see what was created.
- **OpenAI API compatibility**: Think endpoints follow the OpenAI API format
  (`/v1/chat/completions`, `/v1/models`). Any OpenAI-compatible client works.
- **CLI aliases**: `mi` for `modelinstance`/`instance`, `ls` for `list`, `rm`/
  `del` for `delete`, `new` for `create`.
