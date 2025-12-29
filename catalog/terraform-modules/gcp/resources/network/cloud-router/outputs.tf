output "router_id" {
  description = "The ID of the Cloud Router"
  value       = google_compute_router.router.id
}

output "router_self_link" {
  description = "The self_link of the Cloud Router"
  value       = google_compute_router.router.self_link
}

output "router_creation_timestamp" {
  description = "The creation timestamp of the Cloud Router"
  value       = google_compute_router.router.creation_timestamp
}
