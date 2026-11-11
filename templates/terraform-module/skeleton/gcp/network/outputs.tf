output "network_id" {
  description = "ID of the VPC (projects/<project>/global/networks/<name>)."
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "Name of the VPC."
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "Self link of the VPC."
  value       = google_compute_network.main.self_link
}

output "subnet_names" {
  description = "Subnet names ordered private, public, database."
  value       = [for key in local.subnet_order : google_compute_subnetwork.main[key].name]
}

output "subnet_ids" {
  description = "Subnet IDs keyed by tier (private, public, database)."
  value       = { for key, subnet in google_compute_subnetwork.main : key => subnet.id }
}

output "subnet_self_links" {
  description = "Subnet self links keyed by tier (private, public, database)."
  value       = { for key, subnet in google_compute_subnetwork.main : key => subnet.self_link }
}

output "subnet_cidrs" {
  description = "Subnet primary ranges keyed by tier (private, public, database)."
  value       = local.subnets
}

output "gke_pods_range_name" {
  description = "Name of the secondary range for GKE pods on the private subnet, or null when disabled."
  value       = var.enable_gke_secondary_ranges ? local.pods_range_name : null
}

output "gke_services_range_name" {
  description = "Name of the secondary range for GKE services on the private subnet, or null when disabled."
  value       = var.enable_gke_secondary_ranges ? local.services_range_name : null
}

output "private_ip_range" {
  description = "Name of the range peered with Google managed services, or null when private service access is disabled."
  value       = var.enable_private_service_access ? google_compute_global_address.private_service_access[0].name : null

  # Consumers may only allocate from the range once the peering exists.
  depends_on = [google_service_networking_connection.private_service_access]
}

output "router_name" {
  description = "Name of the Cloud Router, or null when NAT is disabled."
  value       = var.enable_nat ? google_compute_router.main[0].name : null
}

output "nat_name" {
  description = "Name of the Cloud NAT gateway, or null when NAT is disabled."
  value       = var.enable_nat ? google_compute_router_nat.main[0].name : null
}

output "nat_ips" {
  description = "Static external addresses used by Cloud NAT. Empty when addresses are allocated automatically."
  value       = google_compute_address.nat[*].address
}

output "private_dns_zone_name" {
  description = "Name of the private Cloud DNS zone, or null when disabled."
  value       = var.enable_private_dns ? google_dns_managed_zone.private[0].name : null
}

output "network_tags" {
  description = "Network tags that opt an instance into the firewall rules created here."
  value = {
    iap_ssh      = "allow-iap-ssh"
    health_check = "allow-health-check"
    web          = "web"
  }
}
