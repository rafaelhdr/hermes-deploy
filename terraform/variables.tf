variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "hermes"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cpx22"
}

variable "location" {
  description = "Hetzner datacenter location (fsn1, nbg1, hel1, ash, hil, sin)"
  type        = string
  default     = "fsn1"
}

variable "os_image" {
  description = "OS image for the server"
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_user" {
  description = "Non-root SSH user to create"
  type        = string
  default     = "hermes"
}

variable "ssh_key_fingerprint" {
  description = "Fingerprint of your existing Hetzner SSH key (find it in Hetzner Console → Security → SSH Keys)"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH in"
  type        = list(string)
  default     = ["10.250.163.0/24"]
}

variable "zerotier_network_id" {
  description = "ZeroTier network ID to join on first boot"
  type        = string
  sensitive   = true
}
