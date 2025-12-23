output "network_id" {
  description = "VPC Network ID"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "VPC Network name"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "VPC Network self link"
  value       = google_compute_network.main.self_link
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = google_compute_subnetwork.public.id
}

output "public_subnet_name" {
  description = "Public subnet name"
  value       = google_compute_subnetwork.public.name
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = google_compute_subnetwork.private.id
}

output "private_subnet_name" {
  description = "Private subnet name"
  value       = google_compute_subnetwork.private.name
}

output "gke_subnet_id" {
  description = "GKE subnet ID"
  value       = google_compute_subnetwork.gke.id
}

output "gke_subnet_name" {
  description = "GKE subnet name"
  value       = google_compute_subnetwork.gke.name
}

output "router_name" {
  description = "Cloud Router name"
  value       = google_compute_router.main.name
}

output "nat_name" {
  description = "Cloud NAT name"
  value       = google_compute_router_nat.main.name
}
