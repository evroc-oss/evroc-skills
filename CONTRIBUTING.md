# Contributing to evroc-skills

## Adding a New Skill

1. Create a directory under `skills/<skill-name>/` with:
   - `SKILL.md` — main skill file with YAML frontmatter + instructions
   - `scripts/check-auth.sh` — thin wrapper around `scripts/shared/check-evroc-auth.sh`
   - `references/cli-reference.md` — full CLI flag reference (optional)

2. Follow the frontmatter format:
   ```yaml
   ---
   name: evroc-<name>
   description: "Use when ... Do NOT trigger for ..."
   license: Apache-2.0
   compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
   metadata:
     author: evroc
     version: "1.0"
     category: <infrastructure|networking|security|orchestration|ai>
   allowed-tools: terminal, read_file
   ---
   ```

3. Include these sections in SKILL.md:
   - `## When to Use` — trigger conditions + "Do NOT use for" exclusions
   - `## Prerequisites` — auth check command
   - Operations with completion criteria
   - `## Pitfalls` — domain-specific gotchas

4. Add eval test cases in `tests/evroc-<name>.json` (see `tests/README.md`)

5. If the skill has a `skillgrade` eval, add cases to `eval.yaml` and graders to `graders/check.py`

## Check-auth Script

Use the shared script as a thin wrapper:

```bash
#!/usr/bin/env bash
# evroc-auth-checker for evroc-<name>
exec bash "$(dirname "$0")/../../../scripts/shared/check-evroc-auth.sh" "$@"
```

For skills where project is optional (e.g. IAM, Think):

```bash
#!/usr/bin/env bash
# evroc-auth-checker for evroc-<name>
exec bash "$(dirname "$0")/../../../scripts/shared/check-evroc-auth.sh" --project-optional "$@"
```

## CI

All pushes and PRs run:
1. `tests/runner.py validate` — schema + cross-reference checks
2. `shellcheck` — lint all skill scripts
3. `terraform validate` — validate Rancher Terraform assets

LLM-based evals run on PRs when `EVROC_THINK_API_KEY` is set as a repo secret.

## License

Apache-2.0. All contributions are licensed under the same terms.
