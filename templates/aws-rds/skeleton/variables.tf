# =============================================================================
# AWS RDS - Root Variables
# =============================================================================
# Input variables for the root module. Values are provided via tfvars files
# in the environments/ directory.
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the RDS instance"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
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
