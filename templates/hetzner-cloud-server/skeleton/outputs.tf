# =============================================================================
# Hetzner Cloud Servers - Outputs
# =============================================================================

output "server_ids" {
  description = "IDs of the servers, by name."
  value       = { for server in hcloud_server.this : server.name => server.id }
}

output "public_ipv4_addresses" {
  description = "Public IPv4 address of every server, by name."
  value       = { for server in hcloud_server.this : server.name => server.ipv4_address }
}

output "private_ipv4_addresses" {
  description = "Address of every server on the private network, by name."
  value       = { for index, server in hcloud_server.this : server.name => cidrhost(var.network_cidr, 10 + index) }
}

output "network_id" {
  description = "ID of the private network."
  value       = hcloud_network.this.id
}

output "load_balancer_ipv4" {
  description = "Public IPv4 address of the load balancer. Null when there is none."
  value       = one(hcloud_load_balancer.this[*].ipv4)
}

output "ssh_user" {
  description = "User to sign in with over SSH."
  value       = var.admin_user
}
