# Troubleshooting

Reference for diagnosing and fixing common issues with Rancher on evroc deployments.

## 404 at Rancher URL

The ingress controller (Traefik, built into K3s) starts before Rancher is ready. During the bootstrap window (5–10 minutes), a 404 is normal.

**Check progress:**

```bash
ssh ubuntu@<rancher_node_ip> "sudo cloud-init status"
```

If `status: running`, wait. If `status: done`, check Rancher pods:

```bash
ssh ubuntu@<rancher_node_ip> "sudo k3s kubectl -n cattle-system get pods"
ssh ubuntu@<rancher_node_ip> "sudo k3s kubectl -n cattle-system rollout status deploy/rancher"
```

## Public IP quota exceeded

```
Error: API error (403): Forbidden - admission webhook "publicip-webhook.evroc.com" denied the request: not enough quota to perform request.
```

evroc accounts have a 3-IP quota. This deployment needs 2.

**Fix:**

```bash
evroc networking publicip list
evroc networking publicip delete <ip-id>
```

Free at least 2 IPs, then re-run `terraform apply -auto-approve`.

## K3s not ready

```bash
ssh ubuntu@<rancher_node_ip> "sudo systemctl status k3s"
ssh ubuntu@<rancher_node_ip> "sudo journalctl -u k3s --no-pager | tail -30"
```

## Rancher pods not starting

```bash
ssh ubuntu@<rancher_node_ip> "sudo k3s kubectl -n cattle-system logs -l app=rancher"
```

Common causes:
- cert-manager not ready yet (check with `sudo k3s kubectl -n cert-manager get pods`)
- Insufficient resources on the VM (use `a1a.m` or larger for the Rancher server)

## Rancher Helm chart incompatible with K3s version

```
Error: INSTALLATION FAILED: chart requires kubeVersion: < 1.36.0-0 which is incompatible with Kubernetes v1.36.3+k3s1
```

The Rancher stable Helm chart requires Kubernetes < 1.36.0. K3s defaults to the latest version (v1.36.x), which is too new.

**Fix:** Pin `k3s_version` to `v1.35.7+k3s1` in `terraform.tfvars` and redeploy. This is the default in the current templates.

**Fix on a running node:** Uninstall K3s and reinstall with the pinned version (the env var must be exported before the curl command):

```bash
sudo /usr/local/bin/k3s-uninstall.sh
export INSTALL_K3S_VERSION="v1.35.7+k3s1"
curl -sfL https://get.k3s.io | sh -s - server --cluster-init --tls-san "<rancher_hostname>" --write-kubeconfig-mode "0644" --token "<k3s_token>"
```

Then re-run the Helm installs (cert-manager + Rancher) as described in the "Cloud-init stuck on cert-manager" section above.

## Cloud-init stuck on "Waiting for cert-manager"

If `cloud-init status` shows `running` for more than 10 minutes and `cloud-init-output.log` shows repeated `Error from server (NotFound): namespaces "cert-manager" not found`, the Helm install failed silently.

**Root cause:** Helm defaults to `localhost:8080` but K3s runs on `6443`. Every `helm` and `kubectl` command in cloud-init must use `KUBECONFIG=/etc/rancher/k3s/k3s.yaml`.

**Manual fix on the node:**

```bash
ssh ubuntu@<rancher_node_ip>
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm repo add jetstack https://charts.jetstack.io
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm repo update
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace
sudo k3s kubectl -n cert-manager rollout status deploy/cert-manager
```

## K3s auth failures (401) from workload node

If K3s logs show `Failed to authenticate request` from the workload node IP, the K3s server and agent have mismatched tokens. Both must use the same `--token` value.

**Check:** The server's K3s install line in cloud-init must include `--token "${k3s_token}"` and the variable must be passed through `templatefile()` in `main.tf`.

**Fix on the running node:** Reinstall K3s with the correct token, or destroy and redeploy with the fixed templates.

## Workload node not joining

```bash
ssh ubuntu@<workload_node_ip> "sudo systemctl status k3s-agent"
ssh ubuntu@<workload_node_ip> "sudo journalctl -u k3s-agent --no-pager | tail -30"
```

Common causes:
- K3s token mismatch between server and agent
- Server not ready when agent tried to join (the cloud-init has a 30s sleep, but the server may need longer)
- Security group blocking port 9345 (K3s supervisor port)

## Terraform provider: no credentials / project not set

```
Error: no credentials found: provide 'config_file', explicit credentials, or configure ~/.evroc/config.yaml: environment variables incomplete and CLI config failed to load: invalid CLI config: EVROC_PROJECT is required
```

The evroc Terraform provider requires a project to be set. `evroc login` does not always set one — the `project` field in `~/.evroc/config.yaml` can be empty.

**Fix:** Set the project explicitly:

```bash
# Check if a project is set
evroc config current-project

# If empty, list available projects and set one
evroc iam project list
evroc config set-project <project-name>
```

Or include `--project` when logging in:

```bash
evroc login --project <project-name>
```

The `scripts/prerequisites.sh` script auto-detects and sets the project if it's missing.

## Terraform provider not loading

Verify evroc credentials:

```bash
cat ~/.evroc/config.yaml
```

If missing or incomplete:

```bash
evroc login
```

Then re-initialize:

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

## Terraform state stuck

If a previous `apply` or `destroy` was interrupted:

```bash
terraform state list
```

Target specific resources:

```bash
terraform destroy -target=evroc_virtual_machine.rancher
terraform destroy -target=evroc_virtual_machine.workload
```

Then run a full `terraform destroy` to clean up remaining resources.

## Cloud-init debugging

```bash
# Full timeline
ssh ubuntu@<rancher_node_ip> "sudo cloud-init analyze show"

# Cloud-init logs
ssh ubuntu@<rancher_node_ip> "sudo cat /var/log/cloud-init.log | tail -100"

# Cloud-init output (what ran)
ssh ubuntu@<rancher_node_ip> "sudo cat /var/log/cloud-init-output.log"
```
