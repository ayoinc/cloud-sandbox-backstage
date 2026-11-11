output "network_id" {
  description = "ID of the VPC network."
  value       = module.sandbox.network_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.sandbox.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.sandbox.private_subnet_ids
}

output "bastion_instance_name" {
  description = "Name of the bastion VM, for `gcloud compute ssh --tunnel-through-iap`. Null when the bastion is not included."
  value       = module.sandbox.bastion_instance_name
}

output "bastion_zone" {
  description = "Zone of the bastion VM. Null when the bastion is not included."
  value       = module.sandbox.bastion_zone
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster. Null when GKE is not included."
  value       = module.sandbox.gke_cluster_name
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE API. Null when GKE is not included."
  value       = module.sandbox.gke_cluster_endpoint
  sensitive   = true
}

output "cloudsql_connection_name" {
  description = "Connection name of the Cloud SQL instance. Null when the database is not included."
  value       = module.sandbox.cloudsql_connection_name
}

output "cloudsql_private_ip" {
  description = "Private IP address of the Cloud SQL instance. Null when the database is not included."
  value       = module.sandbox.cloudsql_private_ip
}

output "cloudsql_database_name" {
  description = "Name of the database. Null when the database is not included."
  value       = module.sandbox.cloudsql_database_name
}

output "cloudsql_admin_password" {
  description = "Password of the Cloud SQL user `sandbox_admin`. Null when the database is not included."
  value       = module.sandbox.cloudsql_admin_password
  sensitive   = true
}
