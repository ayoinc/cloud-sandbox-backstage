# =============================================================================
# GCP Cloud SQL - Module Outputs
# =============================================================================
# Outputs from the Cloud SQL module for use by the root configuration.
# =============================================================================

# -----------------------------------------------------------------------------
# Instance Outputs
# -----------------------------------------------------------------------------

output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.name
}

output "instance_id" {
  description = "ID of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.id
}

output "connection_name" {
  description = "Connection name for Cloud SQL Proxy (project:region:instance)"
  value       = google_sql_database_instance.instance.connection_name
}

output "self_link" {
  description = "Self link of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.self_link
}

# -----------------------------------------------------------------------------
# IP Address Outputs
# -----------------------------------------------------------------------------

output "public_ip_address" {
  description = "Public IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.public_ip_address
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.private_ip_address
}

output "ip_addresses" {
  description = "All IP addresses of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.ip_address
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "database_name" {
  description = "Name of the database"
  value       = google_sql_database.database.name
}

output "database_id" {
  description = "ID of the database"
  value       = google_sql_database.database.id
}

# -----------------------------------------------------------------------------
# User Outputs
# -----------------------------------------------------------------------------

output "user_name" {
  description = "Name of the database user"
  value       = google_sql_user.user.name
}

output "user_password" {
  description = "Password for the database user"
  value       = random_password.db_password.result
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Secret Manager Outputs
# -----------------------------------------------------------------------------

output "password_secret_id" {
  description = "Secret Manager secret ID for the database password"
  value       = var.store_password_in_secret_manager ? google_secret_manager_secret.db_password[0].secret_id : null
}

output "password_secret_name" {
  description = "Secret Manager secret name for the database password"
  value       = var.store_password_in_secret_manager ? google_secret_manager_secret.db_password[0].name : null
}

# -----------------------------------------------------------------------------
# SSL Certificate Outputs
# -----------------------------------------------------------------------------

output "ssl_cert" {
  description = "SSL client certificate"
  value       = var.create_ssl_certificate ? google_sql_ssl_cert.client_cert[0].cert : null
  sensitive   = true
}

output "ssl_private_key" {
  description = "SSL client private key"
  value       = var.create_ssl_certificate ? google_sql_ssl_cert.client_cert[0].private_key : null
  sensitive   = true
}

output "server_ca_cert" {
  description = "Server CA certificate"
  value       = google_sql_database_instance.instance.server_ca_cert
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Connection Strings
# -----------------------------------------------------------------------------

output "connection_string_postgres" {
  description = "PostgreSQL connection string (without password)"
  value = can(regex("^POSTGRES", var.database_version)) ? format(
    "postgresql://%s@%s/%s?sslmode=require",
    google_sql_user.user.name,
    coalesce(google_sql_database_instance.instance.private_ip_address, google_sql_database_instance.instance.public_ip_address),
    google_sql_database.database.name
  ) : null
}

output "connection_string_mysql" {
  description = "MySQL connection string (without password)"
  value = can(regex("^MYSQL", var.database_version)) ? format(
    "mysql://%s@%s/%s",
    google_sql_user.user.name,
    coalesce(google_sql_database_instance.instance.private_ip_address, google_sql_database_instance.instance.public_ip_address),
    google_sql_database.database.name
  ) : null
}

# -----------------------------------------------------------------------------
# Cloud SQL Proxy Command
# -----------------------------------------------------------------------------

output "cloud_sql_proxy_command" {
  description = "Command to start Cloud SQL Proxy"
  value = format(
    "cloud-sql-proxy %s --port=5432",
    google_sql_database_instance.instance.connection_name
  )
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "cloud_sql_info" {
  description = "Summary of Cloud SQL instance configuration"
  value = {
    instance_name         = google_sql_database_instance.instance.name
    connection_name       = google_sql_database_instance.instance.connection_name
    database_version      = var.database_version
    region                = var.region
    tier                  = var.tier
    availability_type     = var.availability_type
    disk_size             = var.disk_size
    disk_type             = var.disk_type
    public_ip             = google_sql_database_instance.instance.public_ip_address
    private_ip            = google_sql_database_instance.instance.private_ip_address
    database_name         = google_sql_database.database.name
    user_name             = google_sql_user.user.name
    backups_enabled       = var.enable_backups
    backup_retention_days = var.backup_retention_days
    deletion_protection   = var.deletion_protection
  }
}
