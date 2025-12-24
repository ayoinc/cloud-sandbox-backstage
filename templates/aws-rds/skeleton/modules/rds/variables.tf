# =============================================================================
# AWS RDS Module - Variables
# =============================================================================
# Input variables for the RDS module. These are passed from the root module.
# No Jinja2 template values - pure Terraform.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the RDS instance"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 63
    error_message = "RDS identifier must be between 1 and 63 characters"
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "production", "development"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, production, development"
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for high availability"
  }
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC for security group rules"
  type        = string
}

# -----------------------------------------------------------------------------
# Database Engine Configuration
# -----------------------------------------------------------------------------
variable "engine" {
  description = "Database engine (postgres or mysql)"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "Engine must be postgres or mysql"
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16"
}

variable "engine_family" {
  description = "Database parameter group family (e.g., postgres16, mysql8.0)"
  type        = string
  default     = "postgres16"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------
variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB"
  }
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling (0 to disable)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for storage encryption (uses default if not specified)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "database_name" {
  description = "Name of the default database"
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "port" {
  description = "Database port (default based on engine)"
  type        = number
  default     = null
}

# -----------------------------------------------------------------------------
# High Availability
# -----------------------------------------------------------------------------
variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Backup Configuration
# -----------------------------------------------------------------------------
variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days"
  }
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------
variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval (0 to disable)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be 0, 1, 5, 10, 15, 30, or 60"
  }
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------
variable "publicly_accessible" {
  description = "Make the database publicly accessible"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Maintenance
# -----------------------------------------------------------------------------
variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately (may cause downtime)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
