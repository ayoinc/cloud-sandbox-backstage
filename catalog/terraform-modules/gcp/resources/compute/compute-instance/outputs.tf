output "instance_id" {
  description = "The unique identifier of the compute instance"
  value       = google_compute_instance.this.instance_id
}

output "instance_name" {
  description = "The name of the compute instance"
  value       = google_compute_instance.this.name
}

output "self_link" {
  description = "The self link of the compute instance"
  value       = google_compute_instance.this.self_link
}

output "internal_ip" {
  description = "The internal IP address of the compute instance"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "The external IP address of the compute instance (if assigned)"
  value       = var.external_ip ? google_compute_instance.this.network_interface[0].access_config[0].nat_ip : null
}

output "instance_zone" {
  description = "The zone where the compute instance is located"
  value       = google_compute_instance.this.zone
}
