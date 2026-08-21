---
name: evroc-compute
description: "Use when the user wants to create, list, inspect, update, or delete evroc VMs, disks, snapshots, or placement groups. Requires the evroc CLI. Do NOT trigger for networking, IAM, storage buckets, load balancers, or Think model operations."
license: Apache-2.0
compatibility: "Requires evroc CLI authenticated with evroc login. macOS or Linux."
metadata:
  author: evroc
  version: "1.1"
  category: infrastructure
allowed-tools: terminal, read_file
---

# evroc-compute

Manage evroc compute resources through the `evroc compute` CLI. Covers VMs, disks,
snapshots, and placement groups.

Read the full CLI reference when needed: [`references/cli-reference.md`](references/cli-reference.md).

## When to Use

- User wants to create, list, inspect, update, or delete a VM on evroc
- User wants to create or manage disks on evroc
- User wants to take or manage disk snapshots
- User wants to create placement groups for VM scheduling
- User mentions "evroc" with "VM", "instance", "disk", "snapshot", or "compute"

**Do NOT use for:** networking (public IPs, security groups, subnets, VPCs), IAM,
storage (buckets), load balancers, or Think models.

## Prerequisites

Run the auth check first:

```bash
bash scripts/check-auth.sh
```

If it fails, authenticate:

```bash
evroc login
```

## Virtual Machines

Requires: a pre-existing boot disk, a flavor, a subnet, and a zone.
If the subnet or security group does not exist yet, create them via
evroc-networking first.

Read networking details when needed:
[`references/networking.md`](references/networking.md) or via **evroc-networking** skill.

### List VMs

```bash
# Names only
evroc compute vm list

# YAML output with full details
evroc compute vm list -o yaml

# Filter by label
evroc compute vm list -l "team in (frontend,backend)"
```

### Get VM details

```bash
evroc compute vm get <vm-name> -o yaml
```

### Create a VM

Requires: a pre-existing boot disk, a flavor, a subnet, and a zone.

**Before creating the boot disk, ask the user which OS image they want.**
Available images are listed in [`references/cli-reference.md`](references/cli-reference.md#available-disk-images)
(e.g. `ubuntu-minimal.24-04.1`, `ubuntu.24-04.1`, `rocky.9-6.1`). Do not guess —
present the options and confirm the user's choice.

```bash
# 1. Create boot disk (ask user which image — see references/cli-reference.md)
evroc compute disk create my-boot-disk \
  --image=<image-name> \
  --size-amount=50 \
  --size-unit=GB \
  --zone=a

# 2. Create VM
evroc compute vm create my-vm \
  --vm-virtual-resources-ref=a1a.m \
  --disk=my-boot-disk \
  --boot-from=true \
  --subnet=default-se-sto-a \
  --security-group=my-sg \
  --ssh-authorized-key="ssh-ed25519 AAAA... user@example.com" \
  --zone=a \
  --running=true
```

**Completion criterion:** The VM has a `Ready` condition with `status: "True"` **and**
`virtualMachineStatus: "Running"`. The VM goes through several conditions before Ready
(`SecurityGroupsReady`, `NetworkingReady`, `VMIsRunning`, `Ready`), so checking just
`reason:` or grepping `status:` returns intermediate states like `SecurityGroupsReady`.

### Poll for VM readiness:

- Checking readiness — prefer Python, with jq only as last resort: The status: key appears at both the top level and nested under conditions[] in the YAML/JSON output. Grepping for status: matches the wrong field and returns the condition's status ("True") instead of the condition's type ("Ready"). Prefer a robust parser — try Python first, and fall back to jq only when you know the JSON does not contain unescaped control characters:

#### Preferred — Python using YAML output (avoids unescaped JSON control chars)
evroc compute vm get <vm-name> -o yaml | python3 -c "import sys, yaml; d=yaml.safe_load(sys.stdin); print([c['status'] for c in d['status']['conditions'] if c['type']=='Ready'][0])"

#### Alternative — jq when JSON is clean
evroc compute vm get <vm-name> -o json | jq -r '.status.conditions[] | select(.type=="Ready") | .status'
For VM running state, use .status.virtualMachineStatus.
Why Python first? The evroc output can contain unescaped control characters inside string fields such as cloudInitUserData; these make the JSON technically invalid and break jq with:
jq: parse error: Invalid string: control characters from U+0000 through U+001F must be escaped.
YAML mode plus python3 + pyyaml handles this gracefully.

Do NOT grep for `status:` or `reason:` in YAML — there are multiple condition entries
and grep matches the first one (e.g. `SecurityGroupsReady`), not the overall Ready state.

> **Note on cloud-init timing:** The `Ready` and `Running` conditions indicate the VM
> is up, but cloud-init may still be executing `runcmd` blocks (package installs,
> downloads, service setup). These can take several minutes after the VM becomes
> `Ready`. An application service may not be available even though the VM reports
> `Running`. If the user expects a service to be reachable, wait and probe the
> application port rather than relying solely on the VM's `Ready` condition.

To probe whether an application port is open and accepting connections:

```bash
# Poll the application port — redirect nc output to /dev/null so the
# comparison variable only contains OPEN/CLOSED, not nc's stdout.
for i in $(seq 1 30); do
  if nc -z -w3 <ip> <port> >/dev/null 2>&1; then
    echo "Port <port> is OPEN (attempt $i)"
    break
  fi
  echo "Port <port> closed (attempt $i), waiting..."
  sleep 10
done
```

> **Warning:** Do NOT capture `nc` output into the comparison variable without
> redirecting to `/dev/null`. `nc` prints "Connection to ... succeeded!" to stdout,
> which contaminates the variable and breaks string comparisons — the loop never
> breaks even when the port is open.

### Create a VM with cloud-init

```bash
evroc compute vm create my-vm \
  --vm-virtual-resources-ref=a1a.m \
  --disk=my-boot-disk \
  --boot-from=true \
  --subnet=default-se-sto-a \
  --zone=a \
  --cloud-init-user-data="#cloud-config
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx"
```

**Note on SSH users:** The evroc platform's default SSH user is `NONE` — it does
**not** default to `ubuntu` or `root`. The `--ssh-authorized-key` flag attaches the
key to the cloud-init default user (`NONE`). If your cloud-init config defines a
custom `users:` block, the key passed via `--ssh-authorized-key` is **not**
automatically attached to those custom users. To SSH as a custom user, you must
include the SSH key in that user's `ssh_authorized_keys` field within the
cloud-init config itself.

**Cloud-init `write_files` ordering:** The `write_files` module runs **before**
`users` and `runcmd`. Do **not** use it to create files in directories that are
created by `runcmd` (e.g., `mkdir -p /opt/app`), and do **not** set `owner` to a
user defined in the `users:` block because that user does not exist yet when
`write_files` executes. To avoid silently failed files, use `runcmd` with `tee`
or `cat` instead, or use `bootcmd` to create directories early and leave


**Runtime version compatibility:** When the user's application has runtime
dependencies (Java, Python, Node.js, Go, etc.), verify that the runtime version. **do NOT** assume
installed in the cloud-init `packages:` or `runcmd:` block is compatible with
the application version before deploying. A version mismatch causes the service
to crash silently — the VM is `Ready`, the port probe shows `CLOSED`, but there's
no obvious error without SSH access.


HALT: Before running ANY evroc compute create/update command, you MUST complete the following 6 steps in order. Do NOT proceed to disk/VM creation until the user has explicitly confirmed the compatibility message in Step 4.

1. Identify the application's runtime requirement (e.g. Java xx for an application,
   Python 3.11 for a specific framework, Node 20 for an app) - NOTE: These are only examples. 
 
2. **Web search** the application's official documentation to find the exact **minimum runtime version** required for that application version. Treat
system knowledge as potentially stale — documentation is the source of truth
**You MUST cite the exact URL and the verbatim text/quote from that documentation
that states the runtime requirement. NEVER proceed from just memory.**


3. Once you have the runtime requirement, check the **OS image's package manager**
    (e.g. `openjdk-21-jre-headless` for Ubuntu 24.04, `python3.11` for
    Ubuntu 22.04, `nodejs` from NodeSource). Present the exact package name
    (or alternative installation method if apt does not provide it) to the user.
4. If the OS image's default package manager cannot satisfy the required
    version, add a step in `runcmd` to install the correct runtime (e.g.
    Adoptium tarball, NodeSource repo, deadsnakes PPA, `pyenv`, `rustup`,
    language-specific version managers).
5. Present the compatibility check to the user in this exact format:
       "**[INSERT APPLICATION]** requires **[INSERT RUNTIME] [VERSION]**.
       **[INSERT OS IMAGE]** provides **[INSERT PACKAGE]** which gives
       **[INSERT INSTALLED VERSION]** — confirm this is what you want?"
6. **Only proceed with the cloud-init config once the user confirms.**


Common runtime version pitfalls:
>
> | Runtime | Issue | Fix |
> |---|---|---|
> | **Python** | App needs 3.11+ but image has 3.10 | Install via `deadsnakes` PPA, `pyenv`, or official Python source tarball |
> | **Node.js** | App needs Node 20 but image has Node 18 | Use NodeSource setup script, `nvm`, or official Node.js binaries |
> | **Go** | Binary compiled for wrong arch | Ensure `GOARCH` matches VM arch (amd64 vs arm64) |
> | **Ruby** | App needs Ruby 3.3 but image has 3.0 | Use `rvm` or `rbenv` in `runcmd` |
> | **Rust** | App needs recent cargo/rustc | Install via `rustup` in `runcmd` |


### Update a VM

```bash
# Attach an additional disk
evroc compute vm update my-vm --append --disk=extra-disk --boot-from=false

# Attach a security group
evroc compute vm update my-vm --append --security-group=additional-sg

# Stop / start
evroc compute vm update my-vm --running=false
evroc compute vm update my-vm --running=true

# Assign a public IP
evroc compute vm update my-vm --public-ip=my-public-ip-name
```

## Security Groups

VMs require security groups for network access. Without explicitly assigned
security groups, the VM's firewall will drop all traffic.

### Default security groups

Each project includes four preconfigured security groups:

| Security Group | Allows |
|---|---|
| `default-allow-egress` | All outbound traffic (IPv4 + IPv6). VMs are auto-added unless you specify custom groups. |
| `default-allow-intra-vpc` | All inbound + outbound traffic within the default VPC (inter-VM communication). |
| `default-allow-web-protocols` | HTTP (TCP 80) + HTTPS (TCP 443) from any IP. |
| `default-allow-ssh` | SSH (TCP 22) from any IP. Must be explicitly added. |

### List existing security groups

Before creating a new security group, check what already exists:

```bash
evroc networking securitygroup list
```

### Create a security group

```bash
evroc networking securitygroup create my-sg
```

### Add rules to a security group

```bash
# Allow SSH from anywhere (IPv4)
evroc networking securitygroup addrule my-sg \
  --name=allow-ssh-ipv4 \
  --direction=Ingress \
  --remote-ip-or-cidr=0.0.0.0/0 \
  --port=22 \
  --protocol=TCP

# Allow HTTPS from anywhere (IPv6)
evroc networking securitygroup addrule my-sg \
  --name=allow-https-ipv6 \
  --direction=Ingress \
  --remote-ip-or-cidr=::/0 \
  --port=443 \
  --protocol=TCP
```

> **Note:** IPv4 and IPv6 rules are separate — create one rule per protocol if you need both.

> **Application ports:** In addition to SSH (22), the user's application likely needs
> its own ingress rule for the port it listens on. The default security groups only
> cover SSH (22), HTTP (80), and HTTPS (443) — any other port requires a custom rule.
>
> **Port lookup workflow:** When the user mentions an application by name (e.g.
> PostgreSQL, Redis, Minecraft, Grafana), look up its default port(s) and confirm
> with the user before creating security group rules:
>
> | Common application | Default port(s) | Protocol |
> |---|---|---|
> | PostgreSQL | 5432 | TCP |
> | MySQL | 3306 | TCP |
> | Redis | 6379 | TCP |
> | MongoDB | 27017 | TCP |
> | Elasticsearch | 9200 | TCP |
> | Grafana | 3000 | TCP |
> | Prometheus | 9090 | TCP |
> | Node.js / Express | 3000 | TCP |
> | Django / Flask | 8000 | TCP |
> | FastAPI | 8000 | TCP |
> | Nginx (non-default) | 8080 | TCP |
> | RabbitMQ | 5672 (AMQP), 15672 (mgmt) | TCP |
> | Kafka | 9092 | TCP |
> | MinIO | 9000, 9001 (console) | TCP |
> | etcd | 2379 | TCP |
> | Consul | 8500 (HTTP), 8300 (RPC) | TCP |
>
> This table is not exhaustive. If the application isn't listed or the user has
> customized the port, **ask the user to confirm the exact port(s)** rather than
> assuming the default. Present what you found and get explicit confirmation:
> "PostgreSQL typically listens on port 5432 — is that correct for your setup?"
>
> If the application isn't in the table above and the user doesn't know the port,
> use a web search to look up the application's default port(s), then confirm
> the findings with the user before creating the rule.

### Attach a security group to a VM

```bash
# Append (keeps existing groups)
evroc compute vm update my-vm --append --security-group=my-sg

# Replace all security groups (must specify ALL groups the VM should have)
evroc compute vm update my-vm \
  --security-group=default-allow-egress \
  --security-group=my-sg
```

> **Warning:** Without `--append`, the update replaces all existing security groups. You must specify the complete list.

### Pre-flight checklist before VM creation

Before creating a VM, verify or create these prerequisites:

1. **Boot disk** — create and wait for `Ready` condition (see [Disks](#disks))
2. **Security group** — either use a default (e.g. `default-allow-ssh`) or create one with
   `evroc networking securitygroup create` + `addrule`. If the user needs SSH access,
   ensure a rule allows TCP 22. If they need web traffic, allow 80/443. If their
   application uses a custom port, create an ingress rule for it.
3. **Subnet** — use the default `default-<region>-<zone>` or create one
4. **SSH key** — confirm or ask the user for their SSH public key. The platform's
   default SSH user is `NONE` — if the user needs SSH access to a custom user defined
   in cloud-init, the key must be listed in that user's `ssh_authorized_keys` in the
   cloud-init config, not just via `--ssh-authorized-key`

### Delete a VM

```bash
evroc compute vm delete my-vm -f
```

**Completion criterion:** `evroc compute vm get <vm-name>` returns `not found`.

## Disks

### List disks

```bash
evroc compute disk list

evroc compute disk list -o yaml
evroc compute disk list -l "environment=production"
```

### Get disk details

```bash
evroc compute disk get <disk-name> -o yaml
```

### Create a disk

From an image (ask the user which one — see [`references/cli-reference.md`](references/cli-reference.md#available-disk-images)):

```bash
evroc compute disk create my-disk \
  --image=<image-name> \
  --size-amount=100 \
  --size-unit=GB \
  --zone=a
```

**Completion criterion:** Wait for the disk's `Ready` condition to be `True` before
creating a VM from it. Poll with:

```bash
evroc compute disk get <disk-name> -o json | jq -r '.status.conditions[] | select(.type=="Ready") | .status'
# Returns "True" when ready. Do NOT grep for "status:" in YAML output —
# the top-level status: field and the nested condition status: field both
# match, causing false readings.
```

From a snapshot:

```bash
evroc compute disk create my-disk \
  --snapshot=my-snapshot \
  --zone=a
```

### Delete a disk

```bash
evroc compute disk delete <disk-name> -f
```

**Completion criterion:** `evroc compute disk get <disk-name>` returns `not found`.

## Snapshots

### Create a snapshot

```bash
evroc compute snapshot create my-snapshot --disk-ref=my-disk
```

### List snapshots

```bash
evroc compute snapshot list
```

### Get snapshot details

```bash
evroc compute snapshot get <snapshot-name> -o yaml
```

### Delete a snapshot

```bash
evroc compute snapshot delete <snapshot-name> -f
```

## Placement Groups

### Create a placement group

```bash
evroc compute placementgroup create my-pg \
  --strategy-type=spread \
  --zone=a
```

### List placement groups

```bash
evroc compute placementgroup list
```

### Assign a VM to a placement group

```bash
evroc compute vm create my-vm \
  --vm-virtual-resources-ref=a1a.m \
  --disk=my-boot-disk \
  --boot-from=true \
  --subnet=default-se-sto-a \
  --placement-group=my-pg \
  --zone=a
```

### Delete a placement group

```bash
evroc compute placementgroup delete my-pg
```

## Pitfalls

- **Disk images — ask, don't guess**: There is no `disk image list` CLI command.
  For the live, current list, run:
  ```bash
  bash scripts/get-disk-images.sh
  ```
  This fetches from the API using your current `evroc login` token. The
  [`references/cli-reference.md`](references/cli-reference.md#available-disk-images)
  table is a cache — use it for offline reference or quick browsing only.
  Always have the user confirm their choice from the live list or cache.
  Image names use format `<distro>.<version>.1` (dot before version,
  hyphen within). e.g. `ubuntu-minimal.24-04.1`, not `ubuntu-minimal-24.04.1` — wrong
  separators silently create a disk that never becomes Ready (`DiskImageInvalid`).
- **Checking readiness — use JSON + jq, not YAML grep**: The `status:` key appears at both
  the top level and nested under `conditions[]` in the YAML/JSON output. Grepping for
  `status:` matches the wrong field and returns the condition's status (`"True"`) instead
  of the condition's type (`"Ready"`). Always use:
  `evroc compute <resource> get <name> -o json | jq -r '.status.conditions[] | select(.type=="Ready") | .status'`
  to check readiness. For VM running state, use `.status.virtualMachineStatus`.
- **Wait for disk Ready before VM create**: A disk that is not yet Ready will cause VM
  creation to fail with "disk is not ready". Always poll the disk's Ready condition first.
- **Security groups — check or create before VM creation**: Without explicitly assigned
  security groups, the VM's firewall drops all traffic. Before creating a VM, check
  existing groups with `evroc networking securitygroup list`. If the user needs SSH access,
  ensure `default-allow-ssh` is attached or create a custom group with a TCP 22 ingress
  rule. If the user needs web traffic, ensure 80/443 are allowed. The VM's
  `SecurityGroupsReady` condition will show `True` once groups are resolved.
- **Application ports need ingress rules**: Default security groups only cover SSH (22),
  HTTP (80), and HTTPS (443). If the user's application listens on a different port, you
  must create a custom ingress rule for it before the VM can receive traffic on that port.
  When the user mentions an application by name, look up its default port(s) (see the
  table in [Security Groups](#security-groups)) and confirm with the user before creating
  the rule — do not assume the default port is correct.
- **Default SSH user is `NONE`**: The platform does not default to `ubuntu` or `root`. The
  `--ssh-authorized-key` flag attaches the key to the cloud-init default user (`NONE`).
  If cloud-init defines a custom `users:` block, the key is NOT attached to those users —
  it must be listed in each user's `ssh_authorized_keys` in the cloud-init config.
- **SSH troubleshooting — may be locked out**: If SSH fails for all users (`ubuntu`,
  `root`, custom user), you cannot debug the VM's internal state via SSH. Alternatives:
  check `evroc compute vm get <name> -o json` for status conditions, use cloud-init
  `write_files` to set up monitoring scripts that run without SSH, or redeploy with a
  corrected cloud-init config that attaches the SSH key to the intended user.
- **cloud-init runs after `Ready`**: The VM reports `Ready` and `Running` before
  cloud-init finishes. Package installs, downloads, and service setup in `runcmd` can
  take several minutes after the VM is `Ready`. If the user expects a service to be
  reachable, wait and probe the application port rather than relying on the VM's
  `Ready` condition alone.
- **Runtime version compatibility**: If the application has runtime dependencies (Java,
  Python, Node.js, etc.), verify the runtime version matches the application's
  requirements before deploying. A mismatch causes the service to crash silently — the
  VM is `Ready` but the port stays `CLOSED` and there's no obvious error without SSH.
  Look up the app's minimum runtime version (web search if needed), confirm the correct
  package name in the OS image, and get user confirmation before writing the cloud-init
  config (see [Runtime version compatibility](#create-a-vm-with-cloud-init)).
  - **Post-deployment cloud-init validation:** If the application port is closed
  even though the VM is `Ready`, first check `cloud-init status` via SSH. If it
  returns `error`, inspect `/var/log/cloud-init-output.log` for the actual failure
  (common causes: missing parent directories for `write_files`, failed package
  installs, or missing systemd units started in `runcmd` before they were
  created).

  - **SSH host key change warning**: Every new evroc VM generates a fresh SSH host
  key pair. If the assigned public IP was previously used for a different VM, your
  local `~/.ssh/known_hosts` will contain the old key and SSH will refuse to
  connect with a `REMOTE HOST IDENTIFICATION HAS CHANGED` error. This is normal,
  not a man-in-the-middle attack. Fix it by removing the stale entry before the
  next connection:
  ```bash
  ssh-keygen -R <vm-public-ip>
 

- **Disk before VM**: Always create the boot disk first. The VM references it by name.
- **Boot-from flag**: Every disk attachment must specify `--boot-from` (`true` for boot,
  `false` for data).
- **Subnet naming**: Pattern is `default-<region>-<zone>`. The zone in the subnet name must
  match `--zone`.
- **Flavor format**: `<series>.<size>` — e.g. `a1a.m`, `c1a.l`. Series: `a1a` (general),
  `c1a` (compute-optimized), `m1a` (memory-optimized).
- **Delete order**: Delete VMs before their attached disks. Disks must be detached before
  deletion.
- **Output formats**: `-o yaml` (default for `get`), `-o json`, `-o list` (default for `list`,
  shows names only). Use `yaml` or `json` when you need full resource details.
- **Label selectors**: Kubernetes-style syntax: `key=value`, `key in (val1,val2)`, `!key`.
  Works with user labels and system labels.
- **Name rules**: Max 63 chars, lowercase alphanumeric with hyphens, starting/ending
  alphanumeric.
