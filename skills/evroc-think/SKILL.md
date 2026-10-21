---
name: evroc-think
description: "Use when the user wants to deploy, start, stop, update, or delete evroc Think dedicated GPU model instances; list or use shared OpenAI-compatible models; create or manage Think API keys; or launch coding agents with Think as backend. Requires the evroc CLI. Do NOT trigger for bare compute VMs (evroc-compute), IAM tasks (evroc-iam), or non-evroc model providers."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.3"
  category: ai
allowed-tools: terminal, read_file
---

# evroc-think

Manage evroc Think Models — a Model-as-a-Service inference platform hosting leading
open-source AI models on NVIDIA H100 and B200 GPUs.

Two modes of operation:
1. **Shared Models** — managed by evroc, ready to use, OpenAI-compatible endpoints.
2. **Dedicated Model Instances** — isolated GPU resources for a single model.

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, start, stop, or delete a model instance
- User wants to list available models or instance sizes
- User wants to list or use shared models
- User wants to create or manage API keys for Think endpoints
- User wants to launch a coding agent (Claude Code, Codex, Hermes, OpenCode, Aider)
  with Think as backend
- User mentions "evroc" with "Think", "model", "inference", "GPU", "LLM", or "AI model"

**Do NOT use for:** compute VMs, networking (public IPs, security groups, subnets, VPCs), IAM, storage, load balancers, or non-evroc model providers.

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

## Shared Models

Shared Models are managed by evroc — no deployment needed. All shared models expose
OpenAI API-compatible endpoints.

### List shared models

```bash
evroc think sharedmodel list
```

### Use a shared model (curl example)

```bash
TOKEN=$(evroc think apikey create temp-key)
curl -H "Authorization: Bearer ${TOKEN}" \
  https://models.think.evroc.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"<shared-model-id>","messages":[{"role":"user","content":"Hello"}]}'
```

## Dedicated Model Instances

For more details, read: [`references/dedicated-instances.md`](references/dedicated-instances.md)

### List available models

```bash
evroc think model list
```

### Get model details

```bash
evroc think model get <model-id> -o yaml
```

### List instance sizes

```bash
evroc think size list
```

Sizes encode GPU type + resources, e.g. `1-b200-27c-240g` (1× B200, 27 vCPUs, 240GB RAM).

### Create a dedicated instance

```bash
evroc think instance create my-instance \
  --model openai-gpt-oss-120b \
  --size 1-b200-27c-240g
```

- `--model` — Required. Model ID from `evroc think model list` (dashed format).
- `--size` — Required. Instance size ID from `evroc think size list`.
- `--stopped` — Create in stopped state (default: running).

**Completion criterion:** `evroc think instance get my-instance -o yaml | grep -E '^\s+status:'` shows `Running`.

### List instances

```bash
evroc think instance list
```

### Get instance details

```bash
evroc think instance get my-instance -o yaml
```

### Start / stop

```bash
evroc think instance start my-instance
evroc think instance stop my-instance
```

### Update a model

```bash
evroc think instance update my-instance --model <new-model-id>
```

### Delete an instance

HALT: Before running ANY `evroc think instance delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete the Model Instance '<instance-name>' and
cannot be undone."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<instance-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc think instance delete my-instance --force
```

**Completion criterion:** `evroc think instance get my-instance` returns `not found`.

## API Keys

API keys authenticate requests to Think endpoints (both shared and dedicated).

### Create an API key

```bash
# No expiry
evroc think apikey create my-key

# With expiry
evroc think apikey create my-key --expiry-timestamp 2026-12-31T23:59:59Z
```

### List API keys

```bash
evroc think apikey list
```

### Delete an API key

HALT: Before running ANY `evroc think apikey delete` command, you MUST output
this message to the user VERBATIM before doing anything else:

"This will permanently delete your API Key '<key-name>' and cannot be
undone. Any services using this key will immediately lose access."

Then:
1. List the specific resource(s) that will be deleted (name, type, project)
2. Ask the user to confirm: "Type 'yes' to confirm deletion of '<key-name>'."
3. Wait for the user to explicitly type 'yes'

Do NOT run the delete command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
evroc think apikey delete my-key --force
```

## Coding Agent Integration

Think can serve as the model backend for coding agents.

### One-off session (no config files written)

```bash
# Claude Code
evroc think code claude

# Codex
evroc think code codex

# Hermes Agent
evroc think code hermes

# OpenCode
evroc think code opencode

# Aider
evroc think code aider
```

This sets `OPENAI_API_KEY` and `OPENAI_BASE_URL` for the session and spawns the agent.
An API key is created automatically if you're logged in. A project is created
automatically if you don't have one.

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

## Inference API

Think exposes `https://models.think.evroc.com/v1` with OpenAI-compatible endpoints.

### List models via API

```bash
TOKEN=$(evroc think apikey create temp-key)
curl -s -H "Authorization: Bearer ${TOKEN}" \
  https://models.think.evroc.com/v1/models | python3 -c \
  "import sys,json; [print(m['id']) for m in json.load(sys.stdin)['data']]"
```

## Quota errors (InsufficientQuota)

Dedicated instance creation fails with HTTP 403 when the organization's GPU quota is exhausted. The API response contains `reason: "InsufficientQuota"` and the text `not enough quota to perform request`.

Committed quotas are org-wide: current usage in ANY project of the organization counts against the same GPU limit. A 403 on an empty project usually means another project (or a GPU VM) consumed the GPU quota.

HALT: When an `instance create` command fails with HTTP 403 and a body containing
"InsufficientQuota" (or the text "not enough quota to perform request"), you MUST:

1. Run: `bash scripts/check-quota.sh gpus` (or `evroc quotas orgquotas get`)
2. Report to the user VERBATIM: for each GPU model, current usage and limit — e.g.
   "GPUs B200: 2/2 used — at limit"
3. State: "To request a quota increase, contact support@evroc.com"
4. Do NOT retry the command until the user decides (stop/delete unused dedicated
   instances via evroc-compute, reduce the instance size, or contact support).
   A silence or ambiguous response is NOT confirmation to retry.

## Pitfalls

- **Dedicated vs shared**: Shared models are zero-deployment. Dedicated instances
  require choosing a model and size, then waiting for deployment.
- **Model IDs use dashed format** matching `evroc think model list` output: e.g. `openai-gpt-oss-120b`,
  not HuggingFace slash format.
- **Size format**: Encodes GPU + resources, e.g. `1-b200-27c-240g`. Run
  `evroc think size list` for the authoritative list.
- **API key expiry**: Keys created without `--expiry-timestamp` have no expiry.
  Set an expiry for short-lived access.
- **Code integration auto-creates resources**: `evroc think code` and
  `evroc think code init` auto-create an API key and project if missing. Check
  `evroc think apikey list` after to see what was created.
- **OpenAI API compatibility**: Endpoints follow OpenAI format.
  Any OpenAI-compatible client works.
- **Dedicated instances consume org GPU quota**: GPU-backed dedicated instances count against
  `compute.gpus.<model>` in the org quota, shared with GPU VM flavors. Check real availability with
  `bash scripts/check-quota.sh gpus` or `evroc quotas orgquotas get` before creating.
- **CLI aliases**: `mi` for `modelinstance`/`instance`, `ls` for `list`,
  `rm`/`del` for `delete`, `new` for `create`.
