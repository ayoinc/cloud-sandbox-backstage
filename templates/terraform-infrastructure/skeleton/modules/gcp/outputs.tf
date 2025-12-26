# GCP Module Outputs

# VPC Outputs
output "vpc_network" {
  description = "Name of the VPC network"
  value       = var.enable_networking ? google_compute_network.main.name : null
}

output "vpc_id" {
  description = "ID of the VPC network"
  value       = var.enable_networking ? google_compute_network.main.id : null
}

# GKE Outputs
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = var.enable_kubernetes ? google_container_cluster.main.name : null
}

output "gke_cluster_endpoint" {
  description = "Endpoint for GKE cluster"
  value       = var.enable_kubernetes ? google_container_cluster.main.endpoint : null
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate for GKE cluster"
  value       = var.enable_kubernetes ? google_container_cluster.main.master_auth[0].cluster_ca_certificate : null
  sensitive   = true
}

output "endpoint" {
  description = "GKE cluster endpoint (alias)"
  value       = var.enable_kubernetes ? google_container_cluster.main.endpoint : null
  sensitive   = true
}

output "ca_certificate" {
  description = "GKE cluster CA certificate (alias)"
  value       = var.enable_kubernetes ? google_container_cluster.main.master_auth[0].cluster_ca_certificate : null
  sensitive   = true
}

# Storage Outputs
output "gcs_bucket_name" {
  description = "Name of the GCS bucket"
  value       = var.enable_storage ? google_storage_bucket.main.name : null
}

output "gcs_bucket_url" {
  description = "URL of the GCS bucket"
  value       = var.enable_storage ? google_storage_bucket.main.url : null
}

# Database Outputs
output "cloudsql_connection_name" {
  description = "Cloud SQL connection name"
  value       = var.enable_database ? google_sql_database_instance.main.connection_name : null
  sensitive   = true
}

# Security Outputs
output "kms_key_id" {
  description = "KMS key ID"
  value       = var.enable_kms ? google_kms_crypto_key.main.id : null
}

output "secret_manager_id" {
  description = "Secret Manager ID"
  value       = var.enable_secret_manager ? google_secret_manager_secret.main.id : null
}

# Networking Outputs
output "load_balancer_ip" {
  description = "Load balancer IP"
  value       = var.enable_kubernetes ? "pending" : null
}
