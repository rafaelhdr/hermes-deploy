output "server_ipv4" {
  description = "Public IPv4 address"
  value       = hcloud_server.hermes.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address"
  value       = hcloud_server.hermes.ipv6_address
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh ${var.ssh_user}@${hcloud_server.hermes.ipv4_address}"
}

output "next_steps" {
  description = "Commands to run after SSH"
  value = [
    "1. ssh ${var.ssh_user}@${hcloud_server.hermes.ipv4_address}",
    "2. Run: hermes setup",
    "3. Optional: sudo systemctl enable --now hermes-gateway (to start the messaging gateway)"
  ]
}
