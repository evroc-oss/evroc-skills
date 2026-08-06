---
name: evroc-rancher
description: Deploy, inspect, and destroy Rancher Manager on evroc cloud using Terraform. Use when the user wants to deploy Rancher on evroc, set up a K3s cluster on evroc VMs, or manage an existing evroc Rancher deployment. Covers the full lifecycle: prerequisites check, interactive variable collection, terraform apply, status polling, and teardown.
license: Apache-2.0
compatibility: Requires terraform, evroc CLI, curl, git, and SSH. macOS or Linux. evroc account with public IP quota (2+ available).
metadata:
  author: evroc
  version: "1.0"
  category: infrastructure
allowed-tools: terminal
---

# evroc-rancher

Deploy Rancher Manager on evroc cloud infrastructure. The skill provisions two VMs via the evroc Terraform provider: a Rancher server node (K3s + cert-manager + Rancher) and a downstream workload node (K3s agent). Cloud-init automates the full software stack.

For troubleshooting and error diagnosis, read [`references/troubleshooting.md`](references/troubleshooting.md).

## When to Use

- User wants to deploy Rancher on evroc
- User wants to destroy an evroc Rancher deployment
- User wants to check the status of a Rancher deployment on evroc
- User mentions "rancher" and "evroc" together in a deployment context

## Prerequisites

Run `scripts/prerequisites.sh` first. It checks for terraform, evroc CLI, evroc authentication, SSH keys, curl, and git — installing terraform via Homebrew if missing. If any prerequisite needs manual action, the script exits non-zero and reports what the user must do.

```bash
bash scripts/prerequisites.sh
```

**Completion criterion:** script exits 0 with "All prerequisites met."

## Operations

Three operations, each with a distinct script. Collect the required inputs from the user before running any script.

### Deploy

1. Collect these **required** values from the user via `clarify`:
   - SSH public key — if `scripts/prerequisites.sh` found one, confirm it; otherwise ask the user to paste it or generate one with `ssh-keygen -t ed25519`.
   - Rancher admin password — must be at least 14 characters. Ask the user to set one.

2. Collect **optional** values, offering defaults:
   - evroc region (default: `se-sto`)
   - evroc zone (default: `a`)
   - resource prefix (default: `rancher`)

3. Choose a work directory. Default: `~/Developer/rancher-evroc-deployment`.

4. Run the deploy script:
   ```bash
   bash scripts/deploy.sh <workdir> "<ssh_public_key>" "<rancher_password>" [region] [zone] [prefix]
   ```

5. Wait for `terraform apply` to complete (~5–8 minutes for provisioning, ~5–10 minutes for cloud-init bootstrap).

**Completion criterion:** `terraform apply` exits 0 and outputs `rancher_server_url`. Report the URL, the node IPs, and the admin password to the user.

### Status

1. Get the Rancher server node IP from the user or from a previous deployment's terraform output.
2. Run:
   ```bash
   bash scripts/status.sh <rancher_node_ip>
   ```
3. The script SSHs into the node and checks: cloud-init status, K3s nodes, Rancher pods, cert-manager pods.

**Completion criterion:** all four checks return output showing resources in Ready/Running state. If any check fails, consult [`references/troubleshooting.md`](references/troubleshooting.md).

### Destroy

1. Confirm the work directory of the deployment to destroy.
2. Run:
   ```bash
   bash scripts/destroy.sh <workdir>
   ```

**Completion criterion:** `terraform destroy` exits 0 with "Destroy complete." Confirm all resources are removed.

## Git Init

After a successful deploy, initialize a git repo in the work directory so the user can version their deployment:

```bash
cd <workdir>
git init
git add -A
git commit -m "Rancher evroc deployment"
```

The user adds their own remote and pushes — the skill does not push to any remote.

## Quick Reference

| Script | Purpose | Usage |
|---|---|---|
| `scripts/prerequisites.sh` | Check and install tools | `bash scripts/prerequisites.sh` |
| `scripts/deploy.sh` | Provision VMs + Rancher | `bash scripts/deploy.sh <workdir> "<ssh_key>" "<password>" [region] [zone] [prefix]` |
| `scripts/destroy.sh` | Tear down everything | `bash scripts/destroy.sh <workdir>` |
| `scripts/status.sh` | Check deployment health | `bash scripts/status.sh <rancher_ip>` |

## Assets

The `assets/` directory contains the Terraform module files. `deploy.sh` copies them into the work directory at deploy time:

| File | Role |
|---|---|
| `main.tf` | evroc provider config, security groups, VMs, disks, public IPs, outputs |
| `variables.tf` | Input variable definitions with defaults |
| `terraform.tfvars.example` | Example variable file for reference |
| `cloud-init-rancher.yaml` | Cloud-init: K3s server + cert-manager + Rancher Helm chart |
| `cloud-init-workload.yaml` | Cloud-init: K3s agent joining the server cluster |

## Pitfalls

- **Public IP quota**: evroc accounts have a 3-IP quota. This deployment needs 2. If the user hits a 403 quota error, they must free IPs with `evroc networking publicip list` + `evroc networking publicip delete <id>`.
- **Bootstrap time**: Rancher takes 5–10 minutes to become ready after VMs are provisioned. A 404 at the Rancher URL during this window is normal — the ingress controller is up before Rancher is ready.
- **SSH key mismatch**: The SSH key in `terraform.tfvars` must match the key used to SSH into the VMs. If the user generated a new key, they must use that key (not a different one) for SSH access.
- **Password requirements**: The Rancher admin password must be at least 14 characters. Shorter passwords cause the Helm install to fail silently.
- **k3s_version empty string**: The default `k3s_version` is `""` which means "latest stable." The cloud-init templates handle this correctly — do not set it to a quoted empty string in tfvars.
