output "network_id" {
  description = "ID of the VPC network."
  value       = google_compute_network.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = google_compute_subnetwork.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = google_compute_subnetwork.private[*].id
}

output "bastion_instance_name" {
  description = "Name of the bastion VM, for `gcloud compute ssh --tunnel-through-iap`. Null when the bastion is not included."
  value       = one(google_compute_instance.bastion[*].name)
}

output "bastion_zone" {
  description = "Zone of the bastion VM. Null when the bastion is not included."
  value       = one(google_compute_instance.bastion[*].zone)
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster. Null when GKE is not included."
  value       = one(google_container_cluster.this[*].name)
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE API. Null when GKE is not included."
  value       = one(google_container_cluster.this[*].endpoint)
  sensitive   = true
}

output "cloudsql_connection_name" {
  description = "Connection name of the Cloud SQL instance. Null when the database is not included."
  value       = one(google_sql_database_instance.this[*].connection_name)
}

output "cloudsql_private_ip" {
  description = "Private IP address of the Cloud SQL instance. Null when the database is not included."
  value       = one(google_sql_database_instance.this[*].private_ip_address)
}

output "cloudsql_database_name" {
  description = "Name of the database. Null when the database is not included."
  value       = one(google_sql_database.this[*].name)
}

output "cloudsql_admin_password" {
  description = "Password of the Cloud SQL user `sandbox_admin`. Null when the database is not included."
  value       = one(random_password.cloudsql[*].result)
  sensitive   = true
}
