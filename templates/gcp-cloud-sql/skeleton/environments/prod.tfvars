{%- set selected = values.environment == 'production' -%}
# =============================================================================
# GCP Cloud SQL - Production Environment Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name             = "${{ values.name }}"
environment      = "prod"
region           = "${{ values.region }}"
project_id       = "${{ values.gcpProject }}"
database_version = "${{ values.database_version }}"
owner            = "${{ (values.owner | parseEntityRef).name }}"

# -----------------------------------------------------------------------------
# Instance Configuration - Production (high availability)
# -----------------------------------------------------------------------------
tier                = "${{ values.tier if selected else 'db-custom-2-7680' }}"
availability_type   = "${{ values.availability_type if selected else 'REGIONAL' }}"
disk_size           = ${{ values.disk_size if selected else 100 }}
disk_type           = "${{ values.disk_type if selected else 'PD_SSD' }}"
disk_autoresize     = true
activation_policy   = "ALWAYS"
deletion_protection = true

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
database_name            = ""
db_user_name             = "app_user"
database_deletion_policy = "ABANDON" # Protect production data
user_deletion_policy     = "ABANDON"

# Database flags for production optimization
database_flags = [
  # PostgreSQL examples:
  # { name = "max_connections", value = "200" },
  # { name = "log_min_duration_statement", value = "1000" },
  # MySQL examples:
  # { name = "slow_query_log", value = "on" },
  # { name = "long_query_time", value = "2" },
]

# -----------------------------------------------------------------------------
# Network Configuration - Production (private recommended)
# -----------------------------------------------------------------------------
enable_private_ip = ${{ values.enable_private_ip if selected else false }}
enable_public_ip  = ${{ not values.enable_private_ip if selected else true }}
network_id        = "${{ values.network_id | default('') if selected }}"
require_ssl       = true

# Authorized networks for production (restrict access)
authorized_networks = [] # Use private IP or specific CIDRs

# -----------------------------------------------------------------------------
# Backup Configuration - Production (maximum retention)
# -----------------------------------------------------------------------------
enable_backups                 = ${{ values.enable_backups if selected else true }}
backup_start_time              = "02:00"
backup_location                = null # Same region as instance
backup_retention_days          = ${{ values.backup_retention_days if selected else 30 }}
enable_point_in_time_recovery  = true
transaction_log_retention_days = 7

# -----------------------------------------------------------------------------
# Maintenance Configuration
# -----------------------------------------------------------------------------
maintenance_window_day   = 7 # Sunday
maintenance_window_hour  = 4 # 4 AM UTC
maintenance_update_track = "stable"

# -----------------------------------------------------------------------------
# Query Insights
# -----------------------------------------------------------------------------
enable_query_insights                  = true
query_insights_string_length           = 4096
query_insights_record_application_tags = true
query_insights_record_client_address   = true

# -----------------------------------------------------------------------------
# Secret Manager
# -----------------------------------------------------------------------------
store_password_in_secret_manager = true

# -----------------------------------------------------------------------------
# SSL Configuration
# -----------------------------------------------------------------------------
create_ssl_certificate = true

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------
labels = {
  cost-center = "production"
  team        = "${{ (values.owner | parseEntityRef).name }}"
  criticality = "high"
  backup      = "required"
}
