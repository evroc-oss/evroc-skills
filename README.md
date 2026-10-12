<div align="center">
  <img src="docs/images/evroc-logo.png" alt="evroc" width="300"/>
</div>

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# evroc-skills

Agent skills for working with evroc cloud infrastructure. Each skill follows the [Agent Skills specification](https://agentskills.io/specification). These skills enable developers to create, modify, and delete resources and services on the [evroc](https://docs.evroc.com/).

This repository is packaged as a portable [Agent Plugin](https://agent-plugins.org/) (spec v1.0.0). The root `plugin.json` manifest declares the plugin identity; the `skills/` directory contains the skill components discovered by any Agent Plugins-compatible client. It also includes a [Claude Plugin](https://claude.com/docs/plugins/build) manifest (`.claude-plugin/plugin.json`) and a [Cursor Plugin](https://cursor.com/docs/plugins) manifest (`.cursor-plugin/plugin.json`) for those clients.

> [!IMPORTANT]
> Large Language Models (LLMs) are probabilistic and may produce inaccurate, inappropriate, or unintended actions. Use caution when using these tools to create and delete resources. 

## Table of Contents
- [Skills Overview](#skills)
- [Repository Structure](#repository-structure)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)
- [Terms and Conditions](#terms-and-conditions)

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
- **Verifiable completion criteria** — exact commands to confirm success
- **`references/`** — CLI flag references and domain-specific guides.
- **`scripts/`** — deterministic helper scripts for fragile operations and auth checks. 

## Repository Structure

```
evroc-skills/
├── plugin.json                    # Agent Plugin manifest (agent-plugins.org)
├── .claude-plugin/plugin.json     # Claude Plugin manifest
├── .cursor-plugin/plugin.json     # Cursor Plugin manifest
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

To install the skills, run the below command:

```
npx skills add evroc-oss/evroc-skills
```

## Usage

Skills are automatically available once installed. The agent will use them when
relevant tasks are detected.

**Examples:**

```
Create a VM with 50GB boot disk and nginx pre-installed
```

```
List all my running VMs and show their public IPs
```

```
Create a security group allowing SSH and HTTP, then attach it to my-vm
```

```
Set up a Think Model instance and give me an API key for it
```

## License

Apache-2.0

## Terms and Conditions 

All code here is covered by the [Terms and Conditions](https://evroc.com/legal/general-terms-and-conditions/) of evroc.
