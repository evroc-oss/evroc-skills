---
name: evroc-rancher
description: "Use when the user wants to deploy, inspect, or destroy Rancher Manager on evroc cloud using Terraform. Covers K3s provisioning, cloud-init automation, and full lifecycle management. Do NOT trigger for bare VM creation (see evroc-compute), networking resources (see evroc-networking), IAM tasks (evroc-iam), or Think model deployment (evroc-think)."
license: Apache-2.0
compatibility: "Requires Terraform, evroc CLI authenticated with evroc login, curl, git, jq, and SSH. macOS or Linux. evroc account needs at least 2 free public IPs (3-IP quota). On first run, terraform init downloads the evroc provider binary (~20 MB) from registry.terraform.io."
metadata:
  author: evroc
  version: "1.2"
  category: orchestration
allowed-tools: terminal, read_file
---

# evroc-rancher

Deploy Rancher Manager on evroc cloud. Provisions a Rancher server node (K3s +
cert-manager + Rancher) and downstream workload nodes (K3s agents) via the evroc
Terraform provider. Cloud-init automates the full software stack.

For troubleshooting, read: [`references/troubleshooting.md`](references/troubleshooting.md).

## When to Use

- User wants to deploy Rancher on evroc
- User wants to destroy an evroc Rancher deployment
- User wants to check the status of a Rancher deployment on evroc
- User mentions "rancher" and "evroc" together in a deployment context

**Do NOT use for:** bare VM creation without Rancher, networking (public IPs,
security groups, subnets, VPCs), IAM tasks, storage buckets, or Think models.

## Prerequisites

Run the prerequisite checker:

```bash
bash scripts/prerequisites.sh
```

If any prerequisite needs manual action, the script exits non-zero and reports what
the user must do.

**Completion criterion:** Script exits 0 with "✓ All prerequisites met."

**Note:** On first run, `terraform init` downloads the evroc Terraform provider
(~20 MB) from `registry.terraform.io`. This requires network access. Subsequent
runs use the local plugin cache.

## Operations

Three operations, each with a dedicated script. Collect required inputs from the
user before running any script.

### Deploy

**Required inputs** (collect via `clarify` if not provided):

1. **SSH public key** — If `prerequisites.sh` found one, confirm it. Otherwise ask
   the user to paste it or generate one with `ssh-keygen -t ed25519`.
2. **Rancher admin password** — Must be at least 14 characters.
3. **Number of workload nodes** — If not specified, ask via `clarify`. Default: 1.
   Each needs a public IP (see IP quota pitfall).

**Optional inputs** (offer defaults):

| Parameter | Default |
|-----------|---------|
| evroc region | `se-sto` |
| evroc zone | `a` |
| resource prefix | `rancher` |

**Deploy workflow** (copy this checklist and track progress):

```
[ ] 1. Prerequisites pass (prerequisites.sh exits 0)
[ ] 2. Inputs collected (SSH key, password, node count)
[ ] 3. Run deploy.sh
[ ] 4. terraform apply exits 0
[ ] 5. VMs provisioned (~5–8 min)
[ ] 6. cloud-init completes (~5–10 min)
[ ] 7. Rancher URL returns 200
[ ] 8. Report URL + credentials to user
```

Run:

```bash
bash scripts/deploy.sh \
  <workdir> \
  "<ssh_public_key>" \
  "<rancher_password>" \
  [region] [zone] [prefix] [workload_node_count]
```

**Completion criterion:** `terraform apply` exits 0 and outputs the Rancher URL.
Report the URL, node IPs, and admin password to the user.

### Status

```bash
bash scripts/status.sh <rancher_node_ip>
```

Checks: cloud-init status, K3s nodes, Rancher pods, cert-manager pods.

**Completion criterion:** All checks show Ready/Running state. If any fail, read
[`references/troubleshooting.md`](references/troubleshooting.md).

### Destroy

HALT: Before running `bash scripts/destroy.sh`, you MUST output this
message to the user VERBATIM before doing anything else:

"This will permanently destroy the entire Rancher deployment and all
associated resources (VMs, disks, public IPs, security groups, networks)
and cannot be undone."

Then:
1. List ALL specific resources that will be destroyed (VM names, disk names,
   public IPs, security groups, networks — everything Terraform manages)
2. Ask the user to confirm: "Type 'yes' to confirm destruction of the entire deployment."
3. Wait for the user to explicitly type 'yes'

Do NOT run the destroy command until the user explicitly confirms.
A silence or ambiguous response is NOT confirmation.

```bash
bash scripts/destroy.sh <workdir>
```

**Completion criterion:** `terraform destroy` exits 0 with "Destroy complete."
Confirm all resources are removed.

## Git Init

After a successful deploy:

```bash
cd <workdir>
git init
git add -A
git commit -m "Rancher evroc deployment"
```

The user manages remotes and pushes themselves.

## Quick Reference

| Script | Purpose | Usage |
|---|---|---|
| `scripts/prerequisites.sh` | Check and install tools | `bash scripts/prerequisites.sh` |
| `scripts/deploy.sh` | Provision VMs + Rancher | `bash scripts/deploy.sh <workdir> "<ssh_key>" "<password>" [region] [zone] [prefix] [count]` |
| `scripts/destroy.sh` | Tear down everything | `bash scripts/destroy.sh <workdir>` |
| `scripts/status.sh` | Check deployment health | `bash scripts/status.sh <rancher_ip>` |

## Assets

The `assets/` directory contains the Terraform module files. `deploy.sh` copies them
into the work directory at deploy time:

| File | Role |
|---|---|
| `main.tf` | Provider, security groups, VMs, disks, public IPs, outputs |
| `variables.tf` | Input variable definitions |
| `terraform.tfvars.example` | Example variable file |
| `cloud-init-rancher.yaml` | Cloud-init: K3s server + cert-manager + Rancher Helm |
| `cloud-init-workload.yaml` | Cloud-init: K3s agent joining the server cluster |

## Pitfalls

- **Public IP quota**: evroc accounts have a 3-IP quota. The deployment needs
  1 IP for the Rancher server + 1 IP per workload node. Run
  `bash scripts/check-public-ip-quota.sh <needed>` before deploying (or use the
  **evroc-networking** skill). If the user hits a 403 quota error, they must free
  IPs via evroc-networking:
  `evroc networking publicip list` + `evroc networking publicip delete <id>`.
- **Bootstrap time**: Rancher takes 5–10 minutes to become ready after VMs are
  provisioned. A 404 at the Rancher URL during this window is normal.
- **SSH key mismatch**: The SSH key in `terraform.tfvars` must match the key used
  to SSH into the VMs.
- **Password requirements**: The Rancher admin password must be at least 14
  characters. Shorter passwords cause the Helm install to fail silently.
- **K3s version**: Pinned to `v1.35.7+k3s1` in `variables.tf` for Rancher chart
  compatibility (requires `kubeVersion < 1.36.0`). Do not override to v1.36.x
  without also bumping the Rancher chart version.
- **Terraform provider**: The `.terraform/` directory is NOT committed. On first
  deploy, `terraform init` downloads the evroc provider from
  `registry.terraform.io`. Requires internet access for the first run.
