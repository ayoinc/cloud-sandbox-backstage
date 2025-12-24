# =============================================================================
# GCP Cloud SQL - Staging Environment Configuration
# =============================================================================
# This file contains Jinja2 template variables that will be substituted
# by Backstage when the template is scaffolded.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name             = "${{ values.name }}"
environment      = "staging"
region           = "${{ values.region }}"
project_id       = "${{ values.gcpProject }}"
database_version = "${{ values.database_version }}"
owner            = "${{ values.owner }}"

# -----------------------------------------------------------------------------
# Instance Configuration - Staging (production-like)
# -----------------------------------------------------------------------------
tier                = "db-g1-small"
availability_type   = "ZONAL"
disk_size           = 20
disk_type           = "PD_SSD"
disk_autoresize     = true
activation_policy   = "ALWAYS"
deletion_protection = true

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
database_name            = ""
db_user_name             = "app_user"
database_deletion_policy = "DELETE"
user_deletion_policy     = "DELETE"
database_flags           = []

# -----------------------------------------------------------------------------
# Network Configuration - Staging
# -----------------------------------------------------------------------------
enable_private_ip = false
enable_public_ip  = true
network_id        = ""
require_ssl       = true

# Authorized networks for staging
authorized_networks = [
  {
    name = "staging-access"
    cidr = "10.0.0.0/8"  # Internal network
  }
]

# -----------------------------------------------------------------------------
# Backup Configuration - Staging (more retention)
# -----------------------------------------------------------------------------
enable_backups                 = true
backup_start_time              = "03:00"
backup_location                = null
backup_retention_days          = 7
enable_point_in_time_recovery  = true
transaction_log_retention_days = 3

# -----------------------------------------------------------------------------
# Maintenance Configuration
# -----------------------------------------------------------------------------
maintenance_window_day   = 7
maintenance_window_hour  = 3
maintenance_update_track = "stable"

# -----------------------------------------------------------------------------
# Query Insights
# -----------------------------------------------------------------------------
enable_query_insights                  = true
query_insights_string_length           = 1024
query_insights_record_application_tags = true
query_insights_record_client_address   = true

# -----------------------------------------------------------------------------
# Secret Manager
# -----------------------------------------------------------------------------
store_password_in_secret_manager = true

# -----------------------------------------------------------------------------
# SSL Configuration
# -----------------------------------------------------------------------------
create_ssl_certificate = false

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------
labels = {
  cost-center = "staging"
  team        = "${{ values.owner }}"
}
