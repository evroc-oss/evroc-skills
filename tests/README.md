# evroc-skills Evaluation Suite

Each skill in this repo includes a set of evaluation prompts used to verify
correct routing, instruction accuracy, and regression safety.

## Format

Each `.json` file contains an array of test cases:

```json
{
  "skill": "evroc-compute",
  "description": "Trigger when user wants to manage VMs, disks, snapshots, or placement groups on evroc",
  "cases": [
    {
      "id": "vm-create-basic",
      "query": "Create a 50GB boot disk called web-server-boot in zone a from the Ubuntu 24.04 image, then create a VM web-server using it",
      "should_trigger": true,
      "expected_behavior": [
        "Runs evroc compute disk create first, before the VM",
        "Uses --image=ubuntu-minimal.24-04.1 for the disk",
        "Uses --disk=web-server-boot and --boot-from=true on the VM",
        "Uses evroc compute vm get to verify the VM is Running"
      ]
    }
  ]
}
```

## How to run

1. Load the skill into your agent system.
2. Feed each `query` as a standalone user prompt.
3. Verify the agent:
   - Triggers the correct skill (`should_trigger`)
   - Follows the steps in `expected_behavior`
   - Respects negative triggers (cases with `should_trigger: false`)

## Coverage

| Skill | Trigger tests | Instruction tests | Negative tests |
|-------|--------------|-------------------|----------------|
| evroc-compute | 5 | 4 | 3 |
| evroc-iam | 4 | 4 | 3 |
| evroc-loadbalancer | 3 | 3 | 2 |
| evroc-rancher | 3 | 3 | 3 |
| evroc-storage | 4 | 3 | 2 |
| evroc-think | 4 | 3 | 3 |
