# =============================================================================
# GCP Cloud SQL - Root Configuration
# =============================================================================
# This is the main entry point that calls the Cloud SQL module.
# Environment-specific values are provided via tfvars files.
# =============================================================================

module "cloud_sql" {
  source = "./modules/cloud-sql"

  # Required variables
  name             = var.name
  environment      = var.environment
  region           = var.region
  project_id       = var.project_id
  database_version = var.database_version
  owner            = var.owner
  labels           = var.labels

  # Instance configuration
  tier                = var.tier
  availability_type   = var.availability_type
  disk_size           = var.disk_size
  disk_type           = var.disk_type
  disk_autoresize     = var.disk_autoresize
  activation_policy   = var.activation_policy
  deletion_protection = var.deletion_protection

  # Database configuration
  database_name            = var.database_name
  db_user_name             = var.db_user_name
  database_deletion_policy = var.database_deletion_policy
  user_deletion_policy     = var.user_deletion_policy
  database_flags           = var.database_flags

  # Network configuration
  enable_private_ip   = var.enable_private_ip
  enable_public_ip    = var.enable_public_ip
  network_id          = var.network_id
  require_ssl         = var.require_ssl
  authorized_networks = var.authorized_networks

  # Backup configuration
  enable_backups                 = var.enable_backups
  backup_start_time              = var.backup_start_time
  backup_location                = var.backup_location
  backup_retention_days          = var.backup_retention_days
  enable_point_in_time_recovery  = var.enable_point_in_time_recovery
  transaction_log_retention_days = var.transaction_log_retention_days

  # Maintenance configuration
  maintenance_window_day   = var.maintenance_window_day
  maintenance_window_hour  = var.maintenance_window_hour
  maintenance_update_track = var.maintenance_update_track

  # Query Insights
  enable_query_insights                  = var.enable_query_insights
  query_insights_string_length           = var.query_insights_string_length
  query_insights_record_application_tags = var.query_insights_record_application_tags
  query_insights_record_client_address   = var.query_insights_record_client_address

  # Secret Manager
  store_password_in_secret_manager = var.store_password_in_secret_manager

  # SSL
  create_ssl_certificate = var.create_ssl_certificate
}
