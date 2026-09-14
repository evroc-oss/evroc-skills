terraform {
  required_providers {
    evroc = {
      source  = "evroc-oss/evroc"
      version = ">= 0.7.0"
    }
  }
}

provider "evroc" {
  # Credentials and context read from ~/.evroc/config.yaml by default.
  # See: https://github.com/evroc-oss/terraform-provider-evroc#1-authenticate-with-evroc
  region = var.evroc_region
}

# Query available disk images and compute profiles
data "evroc_disk_images" "available" {}
data "evroc_compute_profiles" "available" {}

# ====================================
# Security Group
# ====================================

resource "evroc_security_group" "rancher" {
  name = "${var.prefix}-rancher-sg"

  # SSH access
  rule {
    name      = "allow-ssh"
    direction = "Ingress"
    protocol  = "TCP"
    port      = 22
    remote_ip = "0.0.0.0/0"
  }

  # Kubernetes API server
  rule {
    name      = "allow-k8s-api"
    direction = "Ingress"
    protocol  = "TCP"
    port      = 6443
    remote_ip = "0.0.0.0/0"
  }

  # HTTP for Rancher UI / ingress
  rule {
    name      = "allow-http"
    direction = "Ingress"
    protocol  = "TCP"
    port      = 80
    remote_ip = "0.0.0.0/0"
  }

  # HTTPS for Rancher UI / ingress
  rule {
    name      = "allow-https"
    direction = "Ingress"
    protocol  = "TCP"
    port      = 443
    remote_ip = "0.0.0.0/0"
  }

  # K3s supervisor port (for worker nodes to join)
  rule {
    name      = "allow-k3s-supervisor"
    direction = "Ingress"
    protocol  = "TCP"
    port      = 9345
    remote_ip = "0.0.0.0/0"
  }

  # Allow all outbound TCP traffic
  rule {
    name      = "allow-all-tcp-egress"
    direction = "Egress"
    protocol  = "TCP"
    port      = 0
    remote_ip = "0.0.0.0/0"
  }

  # Allow all outbound UDP traffic
  rule {
    name      = "allow-all-udp-egress"
    direction = "Egress"
    protocol  = "UDP"
    port      = 0
    remote_ip = "0.0.0.0/0"
  }
}

# ====================================
# Rancher Server Node
# ====================================

resource "evroc_disk" "rancher_boot" {
  name  = "${var.prefix}-rancher-boot"
  size  = var.rancher_disk_size
  image = data.evroc_disk_images.available.ubuntu_minimal_24_04_1
  zone  = var.evroc_zone
}

resource "evroc_public_ip" "rancher" {
  name = "${var.prefix}-rancher-ip"
}

resource "evroc_virtual_machine" "rancher" {
  name      = "${var.prefix}-rancher"
  flavor    = var.rancher_instance_type
  boot_disk = evroc_disk.rancher_boot.fqid
  zone      = var.evroc_zone

  public_ip       = evroc_public_ip.rancher.fqid
  security_groups = [evroc_security_group.rancher.fqid]

  ssh_keys = [
    var.ssh_public_key
  ]

  cloud_config_user_data = templatefile("${path.module}/cloud-init-rancher.yaml", {
    hostname         = "${var.prefix}-rancher"
    rancher_hostname = "${evroc_public_ip.rancher.ip_address}.sslip.io"
    rancher_password = var.rancher_server_admin_password
    k3s_version      = var.k3s_version
    k3s_token        = var.k3s_token
    public_ssh_keys  = [var.ssh_public_key]
  })
}

# ====================================
# Downstream Workload Nodes
# ====================================

resource "evroc_disk" "workload_boot" {
  count = var.workload_node_count

  name  = "${var.prefix}-workload-${count.index + 1}-boot"
  size  = var.workload_disk_size
  image = data.evroc_disk_images.available.ubuntu_minimal_24_04_1
  zone  = var.evroc_zone
}

resource "evroc_public_ip" "workload" {
  count = var.workload_node_count

  name = "${var.prefix}-workload-${count.index + 1}-ip"
}

resource "evroc_virtual_machine" "workload" {
  count = var.workload_node_count

  name      = "${var.prefix}-workload-${count.index + 1}"
  flavor    = var.workload_instance_type
  boot_disk = evroc_disk.workload_boot[count.index].fqid
  zone      = var.evroc_zone

  public_ip       = evroc_public_ip.workload[count.index].fqid
  security_groups = [evroc_security_group.rancher.fqid]

  ssh_keys = [
    var.ssh_public_key
  ]

  cloud_config_user_data = templatefile("${path.module}/cloud-init-workload.yaml", {
    hostname        = "${var.prefix}-workload-${count.index + 1}"
    k3s_token       = var.k3s_token
    k3s_version     = var.k3s_version
    k3s_server_url  = "https://${evroc_public_ip.rancher.ip_address}:6443"
    public_ssh_keys = [var.ssh_public_key]
  })

  depends_on = [
    evroc_virtual_machine.rancher
  ]
}

# ====================================
# Outputs
# ====================================

output "rancher_node_ip" {
  value       = evroc_public_ip.rancher.ip_address
  description = "Public IP address of the Rancher server node"
}

output "rancher_server_url" {
  value       = "https://${evroc_public_ip.rancher.ip_address}.sslip.io"
  description = "URL to access the Rancher UI"
}

output "workload_node_ips" {
  value       = [for ip in evroc_public_ip.workload : ip.ip_address]
  description = "Public IP addresses of the downstream workload nodes"
}
