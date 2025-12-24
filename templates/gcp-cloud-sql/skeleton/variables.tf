# =============================================================================
# GCP Cloud SQL - Root Variables
# =============================================================================
# These variables are passed to the Cloud SQL module.
# No Jinja2 defaults - values come from environments/*.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the Cloud SQL instance (used in resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud SQL instance"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "database_version" {
  description = "Database engine version (e.g., POSTGRES_15, MYSQL_8_0, SQLSERVER_2019_STANDARD)"
  type        = string
}

# -----------------------------------------------------------------------------
# Optional Metadata
# -----------------------------------------------------------------------------

variable "owner" {
  description = "Owner of the Cloud SQL resources"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Instance Configuration
# -----------------------------------------------------------------------------

variable "tier" {
  description = "Machine tier for the Cloud SQL instance"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type: ZONAL or REGIONAL (for high availability)"
  type        = string
  default     = "ZONAL"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10
}

variable "disk_type" {
  description = "Disk type: PD_SSD or PD_HDD"
  type        = string
  default     = "PD_SSD"
}

variable "disk_autoresize" {
  description = "Enable automatic disk resize"
  type        = bool
  default     = true
}

variable "activation_policy" {
  description = "Activation policy: ALWAYS, NEVER, or ON_DEMAND"
  type        = string
  default     = "ALWAYS"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------

variable "database_name" {
  description = "Name of the database to create (defaults to instance name with underscores)"
  type        = string
  default     = ""
}

variable "db_user_name" {
  description = "Name of the database user to create"
  type        = string
  default     = "app_user"
}

variable "database_deletion_policy" {
  description = "Deletion policy for database: ABANDON or DELETE"
  type        = string
  default     = "DELETE"
}

variable "user_deletion_policy" {
  description = "Deletion policy for user: ABANDON or DELETE"
  type        = string
  default     = "DELETE"
}

variable "database_flags" {
  description = "Database flags to set on the instance"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "enable_private_ip" {
  description = "Enable private IP for the instance"
  type        = bool
  default     = false
}

variable "enable_public_ip" {
  description = "Enable public IP for the instance"
  type        = bool
  default     = true
}

variable "network_id" {
  description = "Full network ID for private IP (projects/PROJECT/global/networks/NETWORK)"
  type        = string
  default     = ""
}

variable "require_ssl" {
  description = "Require SSL for all connections"
  type        = bool
  default     = true
}

variable "authorized_networks" {
  description = "List of authorized networks for public IP access"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Backup Configuration
# -----------------------------------------------------------------------------

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start time for backups in HH:MM format (UTC)"
  type        = string
  default     = "03:00"
}

variable "backup_location" {
  description = "Location for storing backups (region or multi-region)"
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery (PostgreSQL only)"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Number of days to retain transaction logs (1-7)"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# Maintenance Configuration
# -----------------------------------------------------------------------------

variable "maintenance_window_day" {
  description = "Day of week for maintenance window (1=Monday, 7=Sunday)"
  type        = number
  default     = 7
}

variable "maintenance_window_hour" {
  description = "Hour for maintenance window (0-23 UTC)"
  type        = number
  default     = 3
}

variable "maintenance_update_track" {
  description = "Maintenance update track: canary, stable, or week5"
  type        = string
  default     = "stable"
}

# -----------------------------------------------------------------------------
# Query Insights Configuration
# -----------------------------------------------------------------------------

variable "enable_query_insights" {
  description = "Enable Query Insights"
  type        = bool
  default     = true
}

variable "query_insights_string_length" {
  description = "Maximum query string length in Query Insights"
  type        = number
  default     = 1024
}

variable "query_insights_record_application_tags" {
  description = "Record application tags in Query Insights"
  type        = bool
  default     = true
}

variable "query_insights_record_client_address" {
  description = "Record client address in Query Insights"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Secret Manager Configuration
# -----------------------------------------------------------------------------

variable "store_password_in_secret_manager" {
  description = "Store database password in Secret Manager"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# SSL Configuration
# -----------------------------------------------------------------------------

variable "create_ssl_certificate" {
  description = "Create an SSL client certificate"
  type        = bool
  default     = false
}
