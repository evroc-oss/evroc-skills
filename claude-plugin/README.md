# evroc Skills

Agent skills for managing [evroc](https://evroc.com) cloud infrastructure from
Claude Code: compute, networking, storage and KMS, IAM, load balancers, and
Think Models.

## Skills

| Skill | What it covers |
| --- | --- |
| `evroc-compute` | VMs, disks, snapshots, custom disk images, placement groups |
| `evroc-networking` | Public IPv4/IPv6, security groups, subnets, VPCs |
| `evroc-storage` | S3-compatible buckets, file stores, bucket service accounts, KMS keys |
| `evroc-iam` | Projects, role bindings, service accounts, credentials, org users and invitations |
| `evroc-loadbalancer` | Backend pools, services, health checks, L4 routes, listeners |
| `evroc-think` | Dedicated GPU model instances, shared models, API keys, coding agent integration |

Each skill carries routing triggers ("Use when… Do NOT use for…"), verifiable
completion criteria for every operation, explicit confirmation gates before any
destructive command, and a quota failure mode that reads real usage from the
quota API and points at support@evroc.com for increases.

## Requirements

- The **evroc CLI**, installed and on your `PATH`. Follow the installation
  instructions in the [evroc documentation](https://docs.evroc.com/).
- An authenticated session: run `evroc login`.
- `jq` for the quota checks that read JSON output.

The skills never handle your credentials. They rely on the CLI's own
authenticated session, and they will not read, print, or store tokens, private
keys, or S3 credentials on your behalf.

## Usage

The skills load automatically once the plugin is enabled; Claude picks the right
one from your request.

```
Create a VM with a 50GB boot disk and nginx pre-installed
List all my running VMs and show their public IPs
Create a security group allowing SSH and HTTP, then attach it to my-vm
Set up a Think Model instance and give me an API key for it
```

## Terraform-based Rancher deployment

The `evroc-rancher` skill — deploying Rancher Manager on evroc with Terraform —
ships with the Terraform module it needs, so it lives in the main repository
rather than in this plugin:
[github.com/evroc-oss/evroc-skills](https://github.com/evroc-oss/evroc-skills).

## License

Apache-2.0. All code here is covered by the evroc
[Terms and Conditions](https://evroc.com/legal/general-terms-and-conditions/).

> [!IMPORTANT]
> Large Language Models are probabilistic and may produce inaccurate,
> inappropriate, or unintended actions. Use caution when using these skills to
> create and delete cloud resources.
