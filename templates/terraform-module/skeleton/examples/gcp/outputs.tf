output "network_name" {
  description = "VPC network name"
  value       = module.infrastructure.gcp_network_name
}

output "subnet_names" {
  description = "Subnet names"
  value       = module.infrastructure.gcp_subnet_names
}

output "project_id" {
  description = "GCP project ID"
  value       = module.infrastructure.gcp_project_id
}
