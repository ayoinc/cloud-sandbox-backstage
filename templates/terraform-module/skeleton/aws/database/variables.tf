# -----------------------------------------------------------------------------
# AWS Database Module - Variables
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for database"
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "Security groups allowed to access database"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

# RDS Configuration
variable "engine" {
  description = "Database engine (postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.engine)
    error_message = "Engine must be postgres, mysql, or mariadb."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "app"
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "dbadmin"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention" {
  description = "Performance Insights retention in days"
  type        = number
  default     = 7
}

variable "enhanced_monitoring_interval" {
  description = "Enhanced monitoring interval (0 to disable)"
  type        = number
  default     = 60
}

variable "cloudwatch_logs_exports" {
  description = "CloudWatch log exports"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "db_parameters" {
  description = "Database parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = [
    {
      name         = "log_connections"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "log_disconnections"
      value        = "1"
      apply_method = "immediate"
    }
  ]
}

# ElastiCache Configuration
variable "enable_elasticache" {
  description = "Enable ElastiCache Redis"
  type        = bool
  default     = false
}

variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "cache_num_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1
}

variable "cache_snapshot_retention" {
  description = "Cache snapshot retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
