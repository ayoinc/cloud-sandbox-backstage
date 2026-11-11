output "network_id" {
  description = "ID of the network the stack uses, null when there is none."
  value       = local.network_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = local.private_subnet_ids
}

output "network_tags" {
  description = "Network tags the tier firewall rules select instances by (web, app, data), null when enable_security_group_rules is false or there is no network."
  value       = local.tier_rules ? local.tier_tags : null
}

output "kubernetes_cluster_name" {
  description = "Name of the GKE cluster, null when enable_kubernetes is false."
  value       = one(google_container_cluster.this[*].name)
}

output "kubernetes_cluster_endpoint" {
  description = "Address of the Kubernetes API: the private endpoint unless kubernetes_api_allowed_cidrs is set. null when enable_kubernetes is false."
  value       = one(google_container_cluster.this[*].endpoint)
}

output "database_endpoint" {
  description = "Private address of the database (Cloud SQL or Memorystore); connect on the default port of the engine. null when enable_database is false."
  value = (
    local.cloud_sql ? google_sql_database_instance.this[0].private_ip_address :
    local.redis ? google_redis_instance.this[0].host : null
  )
}

output "database_name" {
  description = "Name of the database created in Cloud SQL. null for Redis and when enable_database is false."
  value       = one(google_sql_database.this[*].name)
}

output "database_username" {
  description = "Administrative user of the Cloud SQL database. null for Redis, which uses an AUTH string only, and when enable_database is false."
  value       = one(google_sql_user.admin[*].name)
}

output "database_credentials_secret_id" {
  description = "ID of the Secret Manager secret that holds the generated database credentials as JSON. null without a database or with enable_secrets_manager false."
  value       = one(google_secret_manager_secret.database[*].id)
}

output "database_password" {
  description = "Generated database password, or the Redis AUTH string. null when the credentials are stored in Secret Manager or there is no database."
  sensitive   = true
  value = (
    local.database_secret ? null :
    local.cloud_sql ? random_password.database[0].result :
    local.redis ? google_redis_instance.this[0].auth_string : null
  )
}

output "storage_bucket_name" {
  description = "Name of the object storage bucket, null when enable_storage is false."
  value       = var.enable_storage ? google_storage_bucket.this["assets"].name : null
}

output "data_lake_bucket_names" {
  description = "Names of the raw and curated data-lake buckets, empty unless infrastructure_type is data-platform or ml-platform."
  value       = [for name in ["raw", "curated"] : google_storage_bucket.this[name].name if local.data_lake]
}

output "cdn_domain_name" {
  description = "Host name of the CDN endpoint: cdn_domain when set, otherwise its IP address. null when enable_cdn is false."
  value       = var.enable_cdn ? coalesce(var.cdn_domain, google_compute_global_address.cdn[0].address) : null
}

output "waf_id" {
  description = "ID of the Cloud Armor security policy; set it as security_policy of your own backend services. null when enable_waf is false."
  value       = one(google_compute_security_policy.this[*].id)
}

output "kms_key_id" {
  description = "ID of the customer-managed key in the primary region, null when enable_kms is false."
  value       = local.kms_key_id
}

output "secrets_store_id" {
  description = "Secret Manager has no store resource: this is the project path that secrets are created under. null when enable_secrets_manager is false."
  value       = var.enable_secrets_manager ? "projects/${var.project_id}" : null
}

output "container_registry_url" {
  description = "Docker registry host and path to push images to, null when the infrastructure type has no registry."
  value       = local.registry ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers[0].repository_id}" : null
}

output "private_dns_zone_name" {
  description = "DNS name of the private zone without the trailing dot, null unless infrastructure_type is networking-foundation."
  value       = local.private_dns ? trimsuffix(google_dns_managed_zone.private[0].dns_name, ".") : null
}

output "backup_vault_id" {
  description = "ID of the Backup and DR vault, null when enable_backup is false."
  value       = one(google_backup_dr_backup_vault.this[*].id)
}

output "log_destination_id" {
  description = "ID of the log bucket, null when enable_monitoring and require_flow_logs are false."
  value       = one(google_logging_project_bucket_config.this[*].id)
}

output "alert_target_id" {
  description = "ID of the Pub/Sub topic that receives every alert, null when enable_alerting is false."
  value       = one(google_pubsub_topic.alerts[*].id)
}

output "prometheus_endpoint" {
  description = "Prometheus HTTP API of Managed Service for Prometheus for this project, null when enable_managed_prometheus is false."
  value       = var.enable_managed_prometheus ? "https://monitoring.googleapis.com/v1/projects/${var.project_id}/location/global/prometheus" : null
}

output "prometheus_query_service_account" {
  description = "Email of the service account allowed to query the metrics, null when enable_managed_prometheus is false."
  value       = one(google_service_account.prometheus_query[*].email)
}

output "grafana_endpoint" {
  description = "Always null: Google Cloud offers no managed Grafana. Point your own Grafana at prometheus_endpoint."
  value       = null
}
