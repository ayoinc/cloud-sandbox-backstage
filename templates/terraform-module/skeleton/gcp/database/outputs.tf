# -----------------------------------------------------------------------------
# GCP Database Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Cloud SQL Instance Outputs
# -----------------------------------------------------------------------------

output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance (project:region:instance)"
  value       = google_sql_database_instance.main.connection_name
}

output "instance_self_link" {
  description = "The self link of the Cloud SQL instance"
  value       = google_sql_database_instance.main.self_link
}

output "instance_service_account_email" {
  description = "The service account email of the Cloud SQL instance"
  value       = google_sql_database_instance.main.service_account_email_address
}

# -----------------------------------------------------------------------------
# IP Address Outputs
# -----------------------------------------------------------------------------

output "private_ip_address" {
  description = "The private IP address of the Cloud SQL instance"
  value       = var.enable_private_ip ? google_sql_database_instance.main.private_ip_address : null
  sensitive   = true
}

output "public_ip_address" {
  description = "The public IP address of the Cloud SQL instance (if enabled)"
  value       = var.enable_public_ip ? google_sql_database_instance.main.public_ip_address : null
  sensitive   = true
}

output "ip_addresses" {
  description = "All IP addresses of the Cloud SQL instance"
  value       = google_sql_database_instance.main.ip_address
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "database_name" {
  description = "The name of the database"
  value       = google_sql_database.main.name
}

output "database_self_link" {
  description = "The self link of the database"
  value       = google_sql_database.main.self_link
}

# -----------------------------------------------------------------------------
# User Outputs
# -----------------------------------------------------------------------------

output "user_name" {
  description = "The database user name"
  value       = google_sql_user.main.name
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Credentials Secret Outputs
# -----------------------------------------------------------------------------

output "credentials_secret_id" {
  description = "The Secret Manager secret ID containing database credentials"
  value       = google_secret_manager_secret.db_credentials.secret_id
}

output "credentials_secret_name" {
  description = "The full Secret Manager secret resource name"
  value       = google_secret_manager_secret.db_credentials.name
}

output "credentials_secret_version" {
  description = "The Secret Manager secret version containing database credentials"
  value       = google_secret_manager_secret_version.db_credentials.name
}

# -----------------------------------------------------------------------------
# Private Service Access Outputs
# -----------------------------------------------------------------------------

output "private_ip_range_name" {
  description = "The name of the allocated private IP range"
  value       = var.enable_private_ip ? google_compute_global_address.private_ip_range[0].name : null
}

output "private_ip_range_address" {
  description = "The allocated private IP range address"
  value       = var.enable_private_ip ? google_compute_global_address.private_ip_range[0].address : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Redis (Memorystore) Outputs
# -----------------------------------------------------------------------------

output "redis_host" {
  description = "The hostname of the Memorystore Redis instance (if enabled)"
  value       = var.enable_redis ? google_redis_instance.main[0].host : null
  sensitive   = true
}

output "redis_port" {
  description = "The port of the Memorystore Redis instance (if enabled)"
  value       = var.enable_redis ? google_redis_instance.main[0].port : null
}

output "redis_current_location_id" {
  description = "The current location ID of the Redis instance (if enabled)"
  value       = var.enable_redis ? google_redis_instance.main[0].current_location_id : null
}

output "redis_read_endpoint" {
  description = "The read endpoint of the Redis instance (if enabled and HA)"
  value       = var.enable_redis && var.redis_tier == "STANDARD_HA" ? google_redis_instance.main[0].read_endpoint : null
  sensitive   = true
}

output "redis_read_endpoint_port" {
  description = "The read endpoint port of the Redis instance (if enabled and HA)"
  value       = var.enable_redis && var.redis_tier == "STANDARD_HA" ? google_redis_instance.main[0].read_endpoint_port : null
}

output "redis_credentials_secret_id" {
  description = "The Secret Manager secret ID containing Redis credentials (if enabled)"
  value       = var.enable_redis ? google_secret_manager_secret.redis_credentials[0].secret_id : null
}

output "redis_credentials_secret_name" {
  description = "The full Secret Manager secret resource name for Redis (if enabled)"
  value       = var.enable_redis ? google_secret_manager_secret.redis_credentials[0].name : null
}

# -----------------------------------------------------------------------------
# Connection Information (for convenience)
# -----------------------------------------------------------------------------

output "connection_info" {
  description = "Connection information for the Cloud SQL instance"
  value = {
    connection_name = google_sql_database_instance.main.connection_name
    database        = google_sql_database.main.name
    user            = google_sql_user.main.name
    private_ip      = var.enable_private_ip ? google_sql_database_instance.main.private_ip_address : null
    public_ip       = var.enable_public_ip ? google_sql_database_instance.main.public_ip_address : null
    port            = startswith(var.database_version, "POSTGRES") ? 5432 : 3306
  }
  sensitive = true
}

output "redis_connection_info" {
  description = "Connection information for Memorystore Redis (if enabled)"
  value = var.enable_redis ? {
    host         = google_redis_instance.main[0].host
    port         = google_redis_instance.main[0].port
    auth_enabled = var.redis_auth_enabled
    tier         = var.redis_tier
  } : null
  sensitive = true
}
