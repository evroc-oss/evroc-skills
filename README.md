# evroc-skills

Agent skills for working with evroc cloud infrastructure. Each skill follows the [Agent Skills specification](https://agentskills.io/specification).

## Skills

| Skill | Description |
|---|---|
| `evroc-rancher` | Deploy, inspect, and destroy Rancher Manager on evroc using Terraform |

## Repository Structure

```
evroc-skills/
├── README.md
└── skills/
    └── evroc-rancher/
        ├── SKILL.md              # Skill metadata + instructions
        ├── scripts/               # Executable scripts
        │   ├── prerequisites.sh
        │   ├── deploy.sh
        │   ├── destroy.sh
        │   └── status.sh
        ├── assets/                # Terraform module files
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── terraform.tfvars.example
        │   ├── cloud-init-rancher.yaml
        │   └── cloud-init-workload.yaml
        └── references/           # On-demand documentation
            └── troubleshooting.md
```

## Installation

### Claude Code

Claude Code discovers skills from `.claude/skills/` (project-level) or `~/.claude/skills/` (global). See the [Claude Code skills docs](https://code.claude.com/docs/en/skills).

**Project-level** (available in this project only):

```bash
git clone https://github.com/evroc-oss/evroc-skills.git
mkdir -p .claude/skills
cp -r evroc-skills/skills/evroc-rancher .claude/skills/
```

**Global** (available in all projects):

```bash
git clone https://github.com/evroc-oss/evroc-skills.git ~/evroc-skills
mkdir -p ~/.claude/skills
ln -s ~/evroc-skills/skills/evroc-rancher ~/.claude/skills/evroc-rancher
```

### Cursor

Cursor discovers skills from `.cursor/skills/`, `.agents/skills/`, `.claude/skills/` (project-level), and `~/.cursor/skills/`, `~/.agents/skills/`, `~/.claude/skills/` (global). See the [Cursor skills docs](https://cursor.com/docs/skills).

**Project-level:**

```bash
git clone https://github.com/evroc-oss/evroc-skills.git
mkdir -p .cursor/skills
cp -r evroc-skills/skills/evroc-rancher .cursor/skills/
```

**Global:**

```bash
git clone https://github.com/evroc-oss/evroc-skills.git ~/evroc-skills
mkdir -p ~/.cursor/skills
ln -s ~/evroc-skills/skills/evroc-rancher ~/.cursor/skills/evroc-rancher
```

### OpenCode

OpenCode discovers skills from `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` (project-level), and `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` (global). See the [OpenCode skills docs](https://opencode.ai/docs/skills/).

**Project-level:**

```bash
git clone https://github.com/evroc-oss/evroc-skills.git
mkdir -p .opencode/skills
cp -r evroc-skills/skills/evroc-rancher .opencode/skills/
```

**Global:**

```bash
git clone https://github.com/evroc-oss/evroc-skills.git ~/evroc-skills
mkdir -p ~/.config/opencode/skills
ln -s ~/evroc-skills/skills/evroc-rancher ~/.config/opencode/skills/evroc-rancher
```

### Hermes Agent

Hermes discovers skills from `~/.hermes/skills/`.

```bash
git clone https://github.com/evroc-oss/evroc-skills.git ~/evroc-skills
ln -s ~/evroc-skills/skills/evroc-rancher ~/.hermes/skills/evroc-rancher
```

## License

Apache-2.0
