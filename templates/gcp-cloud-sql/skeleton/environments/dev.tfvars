# =============================================================================
# GCP Cloud SQL - Development Environment Configuration
# =============================================================================
# This file contains Jinja2 template variables that will be substituted
# by Backstage when the template is scaffolded.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name             = "${{ values.name }}"
environment      = "dev"
region           = "${{ values.region }}"
project_id       = "${{ values.gcpProject }}"
database_version = "${{ values.database_version }}"
owner            = "${{ values.owner }}"

# -----------------------------------------------------------------------------
# Instance Configuration - Development (minimal)
# -----------------------------------------------------------------------------
tier                = "db-f1-micro"
availability_type   = "ZONAL"
disk_size           = 10
disk_type           = "PD_SSD"
disk_autoresize     = true
activation_policy   = "ALWAYS"
deletion_protection = false  # Allow easy cleanup in dev

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
database_name            = ""  # Uses default from instance name
db_user_name             = "app_user"
database_deletion_policy = "DELETE"
user_deletion_policy     = "DELETE"
database_flags           = []

# -----------------------------------------------------------------------------
# Network Configuration - Development (public for easy access)
# -----------------------------------------------------------------------------
enable_private_ip = false
enable_public_ip  = true
network_id        = ""
require_ssl       = true

# Authorized networks for development
authorized_networks = [
  {
    name = "office"
    cidr = "0.0.0.0/0"  # Restrict in production!
  }
]

# -----------------------------------------------------------------------------
# Backup Configuration - Development (minimal)
# -----------------------------------------------------------------------------
enable_backups                 = true
backup_start_time              = "03:00"
backup_location                = null
backup_retention_days          = 3
enable_point_in_time_recovery  = false
transaction_log_retention_days = 1

# -----------------------------------------------------------------------------
# Maintenance Configuration
# -----------------------------------------------------------------------------
maintenance_window_day   = 7  # Sunday
maintenance_window_hour  = 3  # 3 AM UTC
maintenance_update_track = "stable"

# -----------------------------------------------------------------------------
# Query Insights - Development (enabled for debugging)
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
  cost-center = "development"
  team        = "${{ values.owner }}"
}
