output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = google_compute_subnetwork.public[*].id
}

output "public_subnet_names" {
  description = "List of public subnet names"
  value       = google_compute_subnetwork.public[*].name
}

output "public_subnet_self_links" {
  description = "List of public subnet self links"
  value       = google_compute_subnetwork.public[*].self_link
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = google_compute_subnetwork.private[*].id
}

output "private_subnet_names" {
  description = "List of private subnet names"
  value       = google_compute_subnetwork.private[*].name
}

output "private_subnet_self_links" {
  description = "List of private subnet self links"
  value       = google_compute_subnetwork.private[*].self_link
}

output "router_id" {
  description = "ID of the Cloud Router"
  value       = var.enable_nat ? google_compute_router.main[0].id : null
}

output "nat_id" {
  description = "ID of Cloud NAT"
  value       = var.enable_nat ? google_compute_router_nat.main[0].id : null
}

output "private_service_range" {
  description = "Private service access IP range"
  value       = var.enable_private_service_access ? google_compute_global_address.private_service_range[0].address : null
}
