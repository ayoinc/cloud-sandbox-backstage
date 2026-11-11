# =============================================================================
# DigitalOcean Droplets - Outputs
# =============================================================================

output "droplet_ids" {
  description = "IDs of the Droplets, by name."
  value       = { for droplet in digitalocean_droplet.this : droplet.name => droplet.id }
}

output "public_ipv4_addresses" {
  description = "Public IPv4 address of every Droplet, by name. With reserved IPs, use reserved_ipv4_addresses instead."
  value       = { for droplet in digitalocean_droplet.this : droplet.name => droplet.ipv4_address }
}

output "private_ipv4_addresses" {
  description = "Address of every Droplet inside the VPC, by name."
  value       = { for droplet in digitalocean_droplet.this : droplet.name => droplet.ipv4_address_private }
}

output "reserved_ipv4_addresses" {
  description = "Reserved IPv4 addresses, in the order of the Droplets. Empty when reserved IPs are off."
  value       = digitalocean_reserved_ip.this[*].ip_address
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = digitalocean_vpc.this.id
}

output "ssh_user" {
  description = "User to sign in with over SSH."
  value       = var.admin_user
}
