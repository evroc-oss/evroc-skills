variable "prefix" {
  description = "Prefix for all created resources"
  type        = string
  default     = "rancher"
}

variable "evroc_region" {
  description = "evroc region"
  type        = string
  default     = "se-sto"
}

variable "evroc_zone" {
  description = "evroc zone"
  type        = string
  default     = "a"
}

variable "ssh_public_key" {
  description = "SSH public key for accessing the VMs"
  type        = string
}

variable "rancher_server_admin_password" {
  description = "Admin password for created Rancher server. See https://ranchermanager.docs.rancher.com/v2.15/getting-started/installation-and-upgrade/resources/bootstrap-password for password requirements."
  type        = string
  sensitive   = true
}

variable "rancher_instance_type" {
  description = "Compute instance size for the Rancher server node"
  type        = string
  default     = "a1a.m"
}

variable "rancher_disk_size" {
  description = "Boot disk size in GB for the Rancher server node"
  type        = number
  default     = 50
}

variable "workload_instance_type" {
  description = "Compute instance size for the downstream workload node"
  type        = string
  default     = "a1a.s"
}

variable "workload_disk_size" {
  description = "Boot disk size in GB for the downstream workload node"
  type        = number
  default     = 50
}

variable "k3s_token" {
  description = "Shared secret for K3s cluster authentication. Generate with: openssl rand -base64 32"
  type        = string
  default     = "rancher-quickstart-k3s-token-change-me"
  sensitive   = true
}

variable "k3s_version" {
  description = "K3s version to install. Pinned to v1.35.7+k3s1 for Rancher chart compatibility (chart requires kubeVersion < 1.36.0). Find versions at https://github.com/k3s-io/k3s/releases"
  type        = string
  default     = "v1.35.7+k3s1"
}
