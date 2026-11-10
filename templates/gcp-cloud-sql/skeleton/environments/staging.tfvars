{%- set selected = values.environment == 'staging' -%}
# =============================================================================
# GCP Cloud SQL - Staging Environment Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name             = "${{ values.name }}"
environment      = "staging"
region           = "${{ values.region }}"
project_id       = "${{ values.gcpProject }}"
database_version = "${{ values.database_version }}"
owner            = "${{ (values.owner | parseEntityRef).name }}"

# -----------------------------------------------------------------------------
# Instance Configuration - Staging (production-like)
# -----------------------------------------------------------------------------
tier                = "${{ values.tier if selected else 'db-g1-small' }}"
availability_type   = "${{ values.availability_type if selected else 'ZONAL' }}"
disk_size           = ${{ values.disk_size if selected else 20 }}
disk_type           = "${{ values.disk_type if selected else 'PD_SSD' }}"
disk_autoresize     = true
activation_policy   = "ALWAYS"
deletion_protection = true

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
database_name            = ""
db_user_name             = "app_user"
database_deletion_policy = "DELETE"
user_deletion_policy     = ""
database_flags           = []

# -----------------------------------------------------------------------------
# Network Configuration - Staging
# -----------------------------------------------------------------------------
enable_private_ip = ${{ values.enable_private_ip if selected else false }}
enable_public_ip  = ${{ not values.enable_private_ip if selected else true }}
network_id        = "${{ values.network_id | default('') if selected }}"
require_ssl       = true

# Authorized networks for staging
authorized_networks = [
  {
    name = "staging-access"
    cidr = "10.0.0.0/8" # Internal network
  }
]

# -----------------------------------------------------------------------------
# Backup Configuration - Staging (more retention)
# -----------------------------------------------------------------------------
enable_backups                 = ${{ values.enable_backups if selected else true }}
backup_start_time              = "03:00"
backup_location                = null
backup_retention_days          = ${{ values.backup_retention_days if selected else 7 }}
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
  team        = "${{ (values.owner | parseEntityRef).name }}"
}
