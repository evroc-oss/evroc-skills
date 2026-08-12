# evroc-skills

Agent skills for working with evroc cloud infrastructure. Each skill follows the [Agent Skills specification](https://agentskills.io/specification).

## Skills

| Skill | Description |
|---|---|
| `evroc-rancher` | Deploy, inspect, and destroy Rancher Manager on evroc using Terraform |
| `evroc-compute` | Manage evroc compute resources: VMs, disks, snapshots, and placement groups via the evroc CLI |
| `evroc-storage` | Manage evroc storage: S3-compatible buckets, file stores, and bucket service accounts |
| `evroc-loadbalancer` | Manage evroc load balancers: backend pools, services, health checks, L4 routes, and listeners |
| `evroc-iam` | Manage evroc IAM: projects, role bindings, service accounts, and credentials |
| `evroc-think` | Manage evroc Think Models: dedicated instances, shared models, API keys, and coding agent integration |
| `evroc-networking` | Manage evroc networking: VPCs, subnets, security groups, and public IPs |

Each skill includes:
- **Routing-optimized `description`** — clear "Use when... Do NOT use for..." triggers for agent routing
- **`Pitfalls` section** — highest-value content per the Perplexity "Zen of Skills"
- **Verifiable completion criteria** — exact commands to confirm success
- **`references/`** — CLI flag references and domain-specific guides (progressive disclosure)
- **`scripts/`** — deterministic helper scripts for fragile operations and auth checks

## Repository Structure

```
evroc-skills/
├── README.md
├── CONTRIBUTING.md
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   └── CODEOWNERS
├── scripts/
│   └── shared/
│       └── check-evroc-auth.sh
├── eval.yaml
├── run-eval.sh
├── graders/
│   └── check.py
├── fixtures/
│   └── seed/
├── tests/
│   ├── README.md
│   ├── runner.py
│   ├── bin/
│   │   ├── evroc          # mock CLI for skillgrade
│   │   └── terraform
│   └── evroc-*.json       # eval test cases
└── skills/
    ├── evroc-compute/
    │   ├── SKILL.md
    │   ├── scripts/
    │   │   └── check-auth.sh
    │   └── references/
    │       └── cli-reference.md
    ├── evroc-iam/
    ├── evroc-loadbalancer/
    ├── evroc-networking/
    ├── evroc-rancher/
    ├── evroc-storage/
    └── evroc-think/
```

## Installation

### Claude Code

Claude Code discovers skills from `.claude/skills/` (project-level) or `~/.claude/skills/` (global). See the [Claude Code skills docs](https://code.claude.com/docs/en/skills).

**Project-level** (available in this project only):

```bash
git clone https://github.com/evroc-oss/evroc-skills.git
mkdir -p .claude/skills
cp -r evroc-skills/skills/ .claude/skills/
```

**Global** (available in all projects):

```bash
git clone https://github.com/evroc-oss/evroc-skills.git ~/evroc-skills
mkdir -p ~/.claude/skills
ln -s ~/evroc-skills/skills/ ~/.claude/skills/
```

### Cursor

Cursor discovers skills from `.cursor/skills/`, `.agents/skills/`, `.claude/skills/` (project-level), and `~/.cursor/skills/`, `~/.agents/skills/`, `~/.claude/skills/` (global). See the [Cursor skills docs](https://cursor.com/docs/skills).

**Project-level:**

```bash
git clone https://github.com/evroc-oss/evroc-skills.git
mkdir -p .cursor/skills
cp -r evroc-skills/skills/ .cursor/skills/
```

**Global:**

```bash
git clone https://github.com/evroc-oss/evroc-skills.git ~/evroc-skills
mkdir -p ~/.cursor/skills
ln -s ~/evroc-skills/skills/evroc-rancher ~/.cursor/skills/
```

### OpenCode

OpenCode discovers skills from `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` (project-level), and `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` (global). See the [OpenCode skills docs](https://opencode.ai/docs/skills/).

**Project-level:**

```bash
git clone https://github.com/evroc-oss/evroc-skills.git
mkdir -p .opencode/skills
cp -r evroc-skills/skills/ .opencode/skills/
```

**Global:**

```bash
git clone https://github.com/evroc-oss/evroc-skills.git ~/evroc-skills
mkdir -p ~/.config/opencode/skills
ln -s ~/evroc-skills/skills/ ~/.config/opencode/skills/
```

### Hermes Agent

Hermes discovers skills from `~/.hermes/skills/`.

```bash
git clone https://github.com/evroc-oss/evroc-skills.git ~/evroc-skills
ln -s ~/evroc-skills/skills/ ~/.hermes/skills/
```

## License

Apache-2.0
