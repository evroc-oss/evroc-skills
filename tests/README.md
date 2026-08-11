# evroc-skills Evaluation Suite

Each skill in this repo includes a set of evaluation prompts used to verify
correct routing, instruction accuracy, and regression safety.

## Automated Runner

Two complementary eval systems are included:

### 1. `tests/runner.py` — Lightweight schema validator + LLM routing checker

#### Validate (CI-safe, no LLM required)

Checks schema integrity, cross-references, and coverage:

```bash
python3 tests/runner.py validate
```

Verifies:
- All skills referenced in test files exist in `skills/`
- All `correct_skill` references in negative-trigger tests point to real skills
- Test types are valid (`trigger`, `negative-trigger`, `instruction`)
- Required fields present per test type
- No duplicate test IDs
- Every skill has a test file (warning, not error)
- SKILL.md has `## When to Use` and `## Pitfalls` sections (warning)

#### Eval (LLM-based routing + instruction checks)

Runs each test case through an LLM and checks the result:

```bash
# Using evroc Think (recommended — sovereign inference)
EVROC_THINK_API_KEY=<key> python3 tests/runner.py eval --backend think

# Using OpenAI
OPENAI_API_KEY=<key> python3 tests/runner.py eval

# Dry run (no LLM calls — shows which tests would run)
python3 tests/runner.py eval --dry-run
```

Filters:

```bash
# Single skill only
python3 tests/runner.py eval --skill evroc-compute

# Specific test types only
python3 tests/runner.py eval --types trigger,negative-trigger
```

### 2. `eval.yaml` + `graders/` — Deterministic skillgrade evals

Full end-to-end agent evals using a mock `evroc` CLI (`tests/bin/evroc`).
The agent runs real commands against the mock; graders check command
sequences deterministically.

```bash
# Run the full skillgrade eval suite
./run-eval.sh
```

The mock CLI:
- Records all invocations to `.evroc-calls.log`
- Tracks resource state in `.evroc-state/` (VMs, disks, buckets, etc.)
- Returns realistic output for all services (compute, iam, storage, LB, think, networking)

Graders (`graders/check.py`) verify:
- Correct service routing (trigger / negative-trigger)
- Command ordering (e.g., disk before VM)
- Flag usage (e.g., `--boot-from=false` for data disks)
- Verification commands (e.g., `evroc compute vm get` after create)

### CI Integration

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs:

1. **validate** — schema + cross-reference checks on every push/PR
2. **shellcheck** — lint all skill scripts
3. **terraform-validate** — validate Rancher Terraform assets
4. **eval** — LLM-based routing tests on PRs (requires `EVROC_THINK_API_KEY` secret)

## Manual Format

Each `.json` file contains an array of test cases:

```json
{
  "skill": "evroc-compute",
  "description": "Trigger when user wants to manage VMs, disks, snapshots, or placement groups on evroc",
  "cases": [
    {
      "id": "vm-create-basic",
      "type": "trigger",
      "query": "Create a 50GB boot disk called web-server-boot in zone a from the Ubuntu 24.04 image, then create a VM web-server using it",
      "should_trigger": true,
      "rationale": "Direct VM creation request on evroc cloud"
    },
    {
      "id": "not-trigger-iam",
      "type": "negative-trigger",
      "query": "Grant the computeOperator role to my teammate on evroc",
      "should_trigger": false,
      "correct_skill": "evroc-iam",
      "rationale": "IAM role binding, not compute provisioning"
    },
    {
      "id": "instruction-disk-before-vm",
      "type": "instruction",
      "query": "Create a VM named app-vm in zone a with a 100GB boot disk",
      "expected_behavior": [
        "First creates the disk with evroc compute disk create",
        "Then creates the VM referencing the disk by name",
        "Uses --zone=a consistently for both disk and VM",
        "Verifies with evroc compute vm get app-vm"
      ]
    }
  ]
}
```

### Test Types

| Type | Purpose | Required Fields |
|------|---------|-----------------|
| `trigger` | Verify the skill activates for matching queries | `should_trigger: true`, `rationale` |
| `negative-trigger` | Verify the skill does NOT activate for other skills' queries | `should_trigger: false`, `correct_skill`, `rationale` |
| `instruction` | Verify the skill produces the right commands/steps | `expected_behavior` (array) |

## Coverage

| Skill | Trigger tests | Instruction tests | Negative tests |
|-------|--------------|-------------------|----------------|
| evroc-compute | 5 | 4 | 3 |
| evroc-iam | 4 | 4 | 3 |
| evroc-loadbalancer | 3 | 3 | 2 |
| evroc-rancher | 3 | 3 | 3 |
| evroc-storage | 4 | 3 | 2 |
| evroc-think | 4 | 3 | 3 |
