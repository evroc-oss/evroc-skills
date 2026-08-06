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

## Using a Skill

Copy or symlink the skill directory into your agent's skills folder:

```bash
# For Hermes Agent
cp -r skills/evroc-rancher ~/.hermes/skills/

# Or symlink for live updates
ln -s "$(pwd)/skills/evroc-rancher" ~/.hermes/skills/evroc-rancher
```

## License

Apache-2.0
