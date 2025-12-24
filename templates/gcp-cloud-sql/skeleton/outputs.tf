# =============================================================================
# GCP Cloud SQL - Root Outputs
# =============================================================================
# Exposes outputs from the Cloud SQL module
# =============================================================================

# -----------------------------------------------------------------------------
# Instance Outputs
# -----------------------------------------------------------------------------

output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = module.cloud_sql.instance_name
}

output "instance_id" {
  description = "ID of the Cloud SQL instance"
  value       = module.cloud_sql.instance_id
}

output "connection_name" {
  description = "Connection name for Cloud SQL Proxy (project:region:instance)"
  value       = module.cloud_sql.connection_name
}

output "self_link" {
  description = "Self link of the Cloud SQL instance"
  value       = module.cloud_sql.self_link
}

# -----------------------------------------------------------------------------
# IP Address Outputs
# -----------------------------------------------------------------------------

output "public_ip_address" {
  description = "Public IP address of the Cloud SQL instance"
  value       = module.cloud_sql.public_ip_address
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = module.cloud_sql.private_ip_address
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "database_name" {
  description = "Name of the database"
  value       = module.cloud_sql.database_name
}

# -----------------------------------------------------------------------------
# User Outputs
# -----------------------------------------------------------------------------

output "user_name" {
  description = "Name of the database user"
  value       = module.cloud_sql.user_name
}

output "user_password" {
  description = "Password for the database user"
  value       = module.cloud_sql.user_password
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Secret Manager Outputs
# -----------------------------------------------------------------------------

output "password_secret_id" {
  description = "Secret Manager secret ID for the database password"
  value       = module.cloud_sql.password_secret_id
}

output "password_secret_name" {
  description = "Secret Manager secret name for the database password"
  value       = module.cloud_sql.password_secret_name
}

# -----------------------------------------------------------------------------
# Connection Strings
# -----------------------------------------------------------------------------

output "connection_string_postgres" {
  description = "PostgreSQL connection string (without password)"
  value       = module.cloud_sql.connection_string_postgres
}

output "connection_string_mysql" {
  description = "MySQL connection string (without password)"
  value       = module.cloud_sql.connection_string_mysql
}

# -----------------------------------------------------------------------------
# Cloud SQL Proxy Command
# -----------------------------------------------------------------------------

output "cloud_sql_proxy_command" {
  description = "Command to start Cloud SQL Proxy"
  value       = module.cloud_sql.cloud_sql_proxy_command
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "cloud_sql_info" {
  description = "Summary of Cloud SQL instance configuration"
  value       = module.cloud_sql.cloud_sql_info
}
