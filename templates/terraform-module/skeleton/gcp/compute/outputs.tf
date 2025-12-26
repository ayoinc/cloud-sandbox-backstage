# -----------------------------------------------------------------------------
# GCP Compute Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Instance Group Manager Outputs
# -----------------------------------------------------------------------------

output "instance_group_id" {
  description = "ID of the regional instance group manager"
  value       = google_compute_region_instance_group_manager.main.id
}

output "instance_group_self_link" {
  description = "Self link of the regional instance group manager"
  value       = google_compute_region_instance_group_manager.main.self_link
}

output "instance_group_name" {
  description = "Name of the regional instance group manager"
  value       = google_compute_region_instance_group_manager.main.name
}

output "instance_group" {
  description = "Instance group URL"
  value       = google_compute_region_instance_group_manager.main.instance_group
}

output "instance_group_fingerprint" {
  description = "Fingerprint of the instance group manager"
  value       = google_compute_region_instance_group_manager.main.fingerprint
}

# -----------------------------------------------------------------------------
# Instance Template Outputs
# -----------------------------------------------------------------------------

output "instance_template_id" {
  description = "ID of the instance template"
  value       = google_compute_instance_template.main.id
}

output "instance_template_self_link" {
  description = "Self link of the instance template"
  value       = google_compute_instance_template.main.self_link
}

output "instance_template_name" {
  description = "Name of the instance template"
  value       = google_compute_instance_template.main.name
}

output "instance_template_metadata_fingerprint" {
  description = "Metadata fingerprint of the instance template"
  value       = google_compute_instance_template.main.metadata_fingerprint
}

output "instance_template_tags_fingerprint" {
  description = "Tags fingerprint of the instance template"
  value       = google_compute_instance_template.main.tags_fingerprint
}

# -----------------------------------------------------------------------------
# Service Account Outputs
# -----------------------------------------------------------------------------

output "service_account_email" {
  description = "Email of the compute service account"
  value       = google_service_account.compute.email
}

output "service_account_id" {
  description = "ID of the compute service account"
  value       = google_service_account.compute.id
}

output "service_account_unique_id" {
  description = "Unique ID of the compute service account"
  value       = google_service_account.compute.unique_id
}

output "service_account_name" {
  description = "Name of the compute service account"
  value       = google_service_account.compute.name
}

# -----------------------------------------------------------------------------
# Health Check Outputs
# -----------------------------------------------------------------------------

output "health_check_id" {
  description = "ID of the health check"
  value       = google_compute_health_check.main.id
}

output "health_check_self_link" {
  description = "Self link of the health check"
  value       = google_compute_health_check.main.self_link
}

output "health_check_name" {
  description = "Name of the health check"
  value       = google_compute_health_check.main.name
}

# -----------------------------------------------------------------------------
# Autoscaler Outputs
# -----------------------------------------------------------------------------

output "autoscaler_id" {
  description = "ID of the regional autoscaler"
  value       = google_compute_region_autoscaler.main.id
}

output "autoscaler_self_link" {
  description = "Self link of the regional autoscaler"
  value       = google_compute_region_autoscaler.main.self_link
}

output "autoscaler_name" {
  description = "Name of the regional autoscaler"
  value       = google_compute_region_autoscaler.main.name
}

# -----------------------------------------------------------------------------
# Firewall Outputs
# -----------------------------------------------------------------------------

output "firewall_internal_id" {
  description = "ID of the internal firewall rule"
  value       = google_compute_firewall.internal.id
}

output "firewall_internal_self_link" {
  description = "Self link of the internal firewall rule"
  value       = google_compute_firewall.internal.self_link
}

output "firewall_health_check_id" {
  description = "ID of the health check firewall rule"
  value       = google_compute_firewall.health_check.id
}

output "firewall_ssh_id" {
  description = "ID of the SSH firewall rule (if enabled)"
  value       = var.enable_ssh_firewall ? google_compute_firewall.ssh[0].id : null
}

output "firewall_http_id" {
  description = "ID of the HTTP firewall rule (if enabled)"
  value       = var.enable_http_firewall ? google_compute_firewall.http[0].id : null
}

# -----------------------------------------------------------------------------
# Computed Outputs
# -----------------------------------------------------------------------------

output "base_instance_name" {
  description = "Base instance name for the managed instance group"
  value       = google_compute_region_instance_group_manager.main.base_instance_name
}

output "target_size" {
  description = "Current target size of the instance group"
  value       = google_compute_region_instance_group_manager.main.target_size
}

output "distribution_policy_zones" {
  description = "Zones where instances are distributed"
  value       = google_compute_region_instance_group_manager.main.distribution_policy_zones
}

output "named_ports" {
  description = "Named ports configured on the instance group"
  value       = google_compute_region_instance_group_manager.main.named_port
}
