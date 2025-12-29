output "instance_template_id" {
  description = "The ID of the instance template"
  value       = google_compute_instance_template.this.id
}

output "instance_template_self_link" {
  description = "The self_link of the instance template"
  value       = google_compute_instance_template.this.self_link
}

output "instance_group_manager_id" {
  description = "The ID of the instance group manager"
  value       = google_compute_region_instance_group_manager.this.id
}

output "instance_group_manager_self_link" {
  description = "The self_link of the instance group manager"
  value       = google_compute_region_instance_group_manager.this.self_link
}

output "instance_group" {
  description = "The full URL of the instance group"
  value       = google_compute_region_instance_group_manager.this.instance_group
}

output "autoscaler_id" {
  description = "The ID of the autoscaler (null if autoscaling is disabled)"
  value       = var.enable_autoscaling ? google_compute_region_autoscaler.this[0].id : null
}
