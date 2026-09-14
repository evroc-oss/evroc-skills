# evroc-think — Dedicated Model Instances Reference

Complete guide for managing dedicated Think model instances (isolated GPU resources).

## Contents

- [Lifecycle](#lifecycle)
- [Model Selection](#model-selection)
- [Size Selection](#size-selection)
- [Instance States](#instance-states)
- [Updating Instances](#updating-instances)
- [Troubleshooting](#troubleshooting)

## Lifecycle

1. **Choose model** → `evroc think model list`
2. **Choose size** → `evroc think size list`
3. **Create** → `evroc think instance create ...`
4. **Poll** → `evroc think instance get <id> -o yaml` until status == `Running`
5. **Create API key** → `evroc think apikey create ...`
6. **Use endpoint** → `curl https://models.think.evroc.com/v1/chat/completions`
7. **Stop / start / delete** → `evroc think instance stop|start|delete`

## Model Selection

Models use dashed IDs (from `evroc think model list`):

```bash
# Filter by name
evroc think model list | grep "gpt-oss"

# Full details (context length, supported profiles, etc.)
evroc think model get openai-gpt-oss-120b -o yaml
```

## Size Selection

Size format: `<gpu-count>-<gpu-type>-<cpu-count>c-<ram>g`

Example: `1-b200-27c-240g`
- `1` = 1 GPU
- `b200` = NVIDIA B200
- `27c` = 27 vCPUs
- `240g` = 240GB RAM

```bash
# See available sizes with pricing
evroc think size list
```

## Instance States

| State | Meaning |
|-------|---------|
| `Provisioning` | VM is being created, model is downloading |
| `Running` | Ready for inference |
| `Stopped` | VM exists but is powered off (no GPU charge) |
| `Starting` | Transitioning from Stopped to Running |
| `Stopping` | Transitioning from Running to Stopped |
| `Deleting` | Being destroyed |
| `Error` | Something went wrong — check `logs` field |

**Key rule**: You pay for GPU time only while `Running`. A `Stopped` instance keeps its disk state but costs only the disk fee.

## Updating Instances

The only mutable field is the model (`--model`). To change the size, you must delete and recreate the instance.

```bash
# Change the running model
evroc think instance update my-instance --model <new-model-id>
```

**Caveat**: During the model switch, the instance may briefly become unavailable (depends on model size and download speed).

## Troubleshooting

### Instance stuck in `Provisioning`

```bash
# Check logs
evroc think instance get my-instance -o yaml
```

Common causes:
- Model image still downloading (normal for large models, can take 5–15 min)
- GPU type temporarily unavailable in the zone
- Model ID mistyped (check `evroc think model list` for exact ID)

### Instance in `Error` state

```bash
# Delete and recreate
evroc think instance delete my-instance
evroc think instance create my-instance --model <correct-model> --size <correct-size>
```

### API call returns 401

Check the API key:
```bash
# Verify key exists and is not expired
evroc think apikey list
```

### Can't list models

```bash
# Debug: check auth and project
evroc iam get-user-info
evroc config current-project
```

### Out of quota

evroc limits GPU instances per account. If `instance create` fails with a quota error:
```bash
# List existing instances
evroc think instance list

# Stop or delete unused instances before creating new ones
evroc think instance stop unused-instance
```
