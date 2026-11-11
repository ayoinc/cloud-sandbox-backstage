output "instance_group" {
  description = "URL of the instance group, for use as a load balancer backend."
  value       = google_compute_region_instance_group_manager.main.instance_group
}

output "instance_group_manager_id" {
  description = "ID of the regional managed instance group."
  value       = google_compute_region_instance_group_manager.main.id
}

output "instance_group_manager_name" {
  description = "Name of the regional managed instance group."
  value       = google_compute_region_instance_group_manager.main.name
}

output "instance_template_id" {
  description = "ID of the instance template."
  value       = google_compute_instance_template.main.id
}

output "instance_template_self_link" {
  description = "Self link of the instance template."
  value       = google_compute_instance_template.main.self_link
}

output "service_account_email" {
  description = "Email of the instance service account."
  value       = google_service_account.compute.email
}

output "health_check_id" {
  description = "ID of the health check."
  value       = google_compute_health_check.main.id
}

output "health_check_self_link" {
  description = "Self link of the health check."
  value       = google_compute_health_check.main.self_link
}

output "autoscaler_name" {
  description = "Name of the autoscaler."
  value       = google_compute_region_autoscaler.main.name
}

output "network_tag" {
  description = "Network tag carried by every instance of the group."
  value       = local.target_tag
}

output "named_port" {
  description = "Named port exposed by the instance group."
  value = {
    name = "http"
    port = var.app_port
  }
}

output "zones" {
  description = "Zones the instances are spread across."
  value       = local.zones
}
