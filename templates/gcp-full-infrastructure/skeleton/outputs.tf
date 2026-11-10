output "name_prefix" {
  description = "Prefix of every resource name"
  value       = local.name_prefix
}

output "enabled_services" {
  description = "APIs enabled for the selected categories"
  value       = sort(local.services)
}

output "network_id" {
  description = "ID of the VPC network in use"
  value       = local.network_id
}

output "subnet_ids" {
  description = "IDs of the created subnets by name"
  value       = { for name, subnet in google_compute_subnetwork.main : name => subnet.id }
}

output "instance_group" {
  description = "Managed instance group of the Compute Engine instances"
  value       = one(google_compute_region_instance_group_manager.main[*].instance_group)
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = one(google_container_cluster.main[*].name)
}

output "gke_get_credentials_command" {
  description = "Command that configures kubectl for the GKE cluster"
  value       = var.enable_containers ? "gcloud container clusters get-credentials ${google_container_cluster.main[0].name} --region ${var.region} --project ${var.project_id}" : null
}

output "artifact_registry_repository" {
  description = "Docker repository URL in Artifact Registry"
  value       = var.enable_containers ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].repository_id}" : null
}

output "data_bucket" {
  description = "Name of the data bucket"
  value       = one(google_storage_bucket.data[*].name)
}

output "filestore_ip_address" {
  description = "IP address of the Filestore instance"
  value       = try(google_filestore_instance.main[0].networks[0].ip_addresses[0], null)
}

output "cloudsql_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = one(google_sql_database_instance.main[*].name)
}

output "cloudsql_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = one(google_sql_database_instance.main[*].connection_name)
}

output "cloudsql_password_secret" {
  description = "Secret Manager secret that holds the Cloud SQL password"
  value       = one(google_secret_manager_secret.cloudsql_password[*].secret_id)
}

output "firestore_database" {
  description = "Name of the Firestore database"
  value       = one(google_firestore_database.main[*].name)
}

output "redis_host" {
  description = "Host of the Memorystore Redis instance"
  value       = one(google_redis_instance.main[*].host)
}

output "kms_key_id" {
  description = "ID of the Cloud KMS key"
  value       = one(google_kms_crypto_key.main[*].id)
}

output "app_service_account" {
  description = "Email of the application service account"
  value       = one(google_service_account.app[*].email)
}

output "bigquery_dataset" {
  description = "ID of the BigQuery dataset"
  value       = one(google_bigquery_dataset.main[*].dataset_id)
}

output "pubsub_topic" {
  description = "Name of the Pub/Sub topic"
  value       = one(google_pubsub_topic.events[*].name)
}

output "vertex_bucket" {
  description = "Name of the Vertex AI artifact bucket"
  value       = one(google_storage_bucket.vertex[*].name)
}

output "cloud_run_url" {
  description = "URL of the Cloud Run service"
  value       = one(google_cloud_run_v2_service.main[*].uri)
}
