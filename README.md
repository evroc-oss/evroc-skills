<div align="center">
  <img src="docs/images/evroc-logo.png" alt="evroc" width="300"/>
</div>
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# evroc-skills

Agent skills for working with evroc cloud infrastructure. Each skill follows the [Agent Skills specification](https://agentskills.io/specification).

## Skills

| Skill | Description |
| --- | --- |
| `evroc-rancher` | Deploy, inspect, and destroy Rancher Manager on evroc using Terraform |
| `evroc-networking` | Create, manage, and delete public IPs, security groups, subnets, and VPCs on evroc cloud |
| `evroc-compute` | Manage evroc compute resources: VMs, disks, snapshots, and placement groups via the evroc CLI |
| `evroc-storage` | Manage evroc storage: S3-compatible buckets, file stores, and bucket service accounts |
| `evroc-loadbalancer` | Manage evroc load balancers: backend pools, services, health checks, L4 routes, and listeners |
| `evroc-iam` | Manage evroc IAM: projects, role bindings, service accounts, and credentials |
| `evroc-think` | Manage evroc Think Models: dedicated instances, shared models, API keys, and coding agent integration |

Each skill includes:

- **Routing-optimized `description`** — clear "Use when... Do NOT use for..." triggers for agent routing
- **`Pitfalls` section** — highest-value content per the Perplexity "Zen of Skills"
- **Verifiable completion criteria** — exact commands to confirm success
- **`references/`** — CLI flag references and domain-specific guides.
- **`scripts/`** — deterministic helper scripts for fragile operations and auth checks. 

## Repository Structure

```
evroc-skills/
├── README.md
└── skills/
    ├── evroc-compute/
    │   ├── SKILL.md
    │   ├── scripts/
    │   │   └── check-auth.sh
    │   └── references/
    │       └── cli-reference.md
    ├── evroc-iam/
    │   ├── SKILL.md
    │   ├── scripts/
    │   │   └── check-auth.sh
    │   └── references/
    │       └── cli-reference.md
    ├── evroc-loadbalancer/
    │   ├── SKILL.md
    │   ├── scripts/
    │   │   └── check-auth.sh
    │   └── references/
    │       └── cli-reference.md
    ├── evroc-rancher/
    │   ├── SKILL.md
    │   ├── scripts/
    │   │   ├── prerequisites.sh
    │   │   ├── deploy.sh
    │   │   ├── destroy.sh
    │   │   ├── status.sh
    │   │   └── check-public-ip-quota.sh
    │   ├── assets/
    │   │   ├── .terraform.lock.hcl
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── terraform.tfvars.example
    │   │   ├── cloud-init-rancher.yaml
    │   │   └── cloud-init-workload.yaml
    │   └── references/
    │       └── troubleshooting.md
    ├── evroc-storage/
    │   ├── SKILL.md
    │   ├── scripts/
    │   │   └── check-auth.sh
    │   └── references/
    │       └── cli-reference.md
    ├── evroc-think/
    │   ├── SKILL.md
    │   ├── scripts/
    │   │   └── check-auth.sh
    │   └── references/
    │       ├── cli-reference.md
    │       └── dedicated-instances.md
    └── evroc-networking/
        ├── SKILL.md
        ├── scripts/
        │   ├── check-auth.sh
        │   └── check-public-ip-quota.sh
        └── references/
            └── cli-reference.md
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
