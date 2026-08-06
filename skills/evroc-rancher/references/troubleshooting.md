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

## Workload node not joining

```bash
ssh ubuntu@<workload_node_ip> "sudo systemctl status k3s-agent"
ssh ubuntu@<workload_node_ip> "sudo journalctl -u k3s-agent --no-pager | tail -30"
```

Common causes:
- K3s token mismatch between server and agent
- Server not ready when agent tried to join (the cloud-init has a 30s sleep, but the server may need longer)
- Security group blocking port 9345 (K3s supervisor port)

## Terraform provider not loading

Verify evroc credentials:

```bash
cat ~/.evroc/config.yaml
```

If missing or incomplete:

```bash
evroc login --domain evroc.com --organization evroc
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
