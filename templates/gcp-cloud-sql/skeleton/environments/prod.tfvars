# =============================================================================
# GCP Cloud SQL - Production Environment Configuration
# =============================================================================
# This file contains Jinja2 template variables that will be substituted
# by Backstage when the template is scaffolded.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name             = "${{ values.name }}"
environment      = "prod"
region           = "${{ values.region }}"
project_id       = "${{ values.gcpProject }}"
database_version = "${{ values.database_version }}"
owner            = "${{ values.owner }}"

# -----------------------------------------------------------------------------
# Instance Configuration - Production (high availability)
# -----------------------------------------------------------------------------
tier                = "${{ values.tier }}"
availability_type   = "${{ values.availability_type }}"
disk_size           = ${{ values.disk_size }}
disk_type           = "${{ values.disk_type }}"
disk_autoresize     = true
activation_policy   = "ALWAYS"
deletion_protection = true

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
database_name            = ""
db_user_name             = "app_user"
database_deletion_policy = "ABANDON"  # Protect production data
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
enable_private_ip = ${{ values.enable_private_ip }}
enable_public_ip  = ${{ values.enable_private_ip | not }}
network_id        = "${{ values.network_id }}"
require_ssl       = true

# Authorized networks for production (restrict access)
authorized_networks = []  # Use private IP or specific CIDRs

# -----------------------------------------------------------------------------
# Backup Configuration - Production (maximum retention)
# -----------------------------------------------------------------------------
enable_backups                 = ${{ values.enable_backups }}
backup_start_time              = "02:00"
backup_location                = null  # Same region as instance
backup_retention_days          = ${{ values.backup_retention_days }}
enable_point_in_time_recovery  = true
transaction_log_retention_days = 7

# -----------------------------------------------------------------------------
# Maintenance Configuration
# -----------------------------------------------------------------------------
maintenance_window_day   = 7  # Sunday
maintenance_window_hour  = 4  # 4 AM UTC
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
  team        = "${{ values.owner }}"
  criticality = "high"
  backup      = "required"
}
