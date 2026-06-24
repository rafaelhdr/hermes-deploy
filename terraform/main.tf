terraform {
  required_version = ">= 1.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.50"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

data "cloudinit_config" "hermes" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init.yaml", {
      non_root_user       = var.ssh_user
      ssh_authorized_key  = data.hcloud_ssh_key.hermes.public_key
      zerotier_network_id = var.zerotier_network_id
    })
  }
}

data "hcloud_ssh_key" "hermes" {
  fingerprint = var.ssh_key_fingerprint
}

resource "hcloud_firewall" "hermes" {
  name = "${var.cluster_name}-firewall"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9119"
    source_ips = var.allowed_ssh_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "9993"
    source_ips = var.allowed_ssh_cidrs
  }
}

resource "hcloud_server" "hermes" {
  name        = "${var.cluster_name}-server"
  server_type = var.server_type
  image       = var.os_image
  location    = var.location
  ssh_keys    = [data.hcloud_ssh_key.hermes.id]
  user_data   = data.cloudinit_config.hermes.rendered

  firewall_ids = [hcloud_firewall.hermes.id]

  public_net {}

  labels = {
    app     = "hermes-agent"
    managed = "terraform"
  }
}
