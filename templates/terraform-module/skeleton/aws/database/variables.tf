# -----------------------------------------------------------------------------
# AWS Database Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as the prefix of every resource name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9._-]*$", var.project_name))
    error_message = "project_name must start with a letter and contain only letters, digits, dots, underscores and hyphens."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,8}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits."
  }
}

variable "vpc_id" {
  description = "ID of the VPC the database is placed in"
  type        = string

  validation {
    condition     = var.vpc_id != null
    error_message = "vpc_id is required. Enable the network module or pass an existing VPC."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs for the database"
  type        = list(string)

  validation {
    condition     = var.subnet_ids != null && length(coalesce(var.subnet_ids, [])) >= 2
    error_message = "subnet_ids must contain at least 2 subnet IDs in different availability zones."
  }
}

variable "allowed_security_groups" {
  description = "Security group IDs allowed to connect to the database and the cache"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "IPv4 CIDR blocks (inside the private network) allowed to connect to the database and the cache"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "allowed_cidr_blocks must be valid IPv4 CIDR blocks and must not include 0.0.0.0/0."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt storage, Performance Insights, the cache and the credential secrets. Null uses the AWS managed keys"
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
    error_message = "engine must be postgres, mysql or mariadb."
  }
}

variable "engine_version" {
  description = "Engine version, major (\"17\", \"8.4\", \"11.4\") or full (\"17.5\"). Null selects the module's current major version for the engine with the newest minor"
  type        = string
  default     = null

  validation {
    condition     = var.engine_version == null || can(regex("^[0-9]+(\\.[0-9]+){0,2}$", coalesce(var.engine_version, "0")))
    error_message = "engine_version must look like 17, 17.5, 8.4 or 8.4.5."
  }

  validation {
    condition     = var.engine_version == null || var.engine == "postgres" || length(split(".", coalesce(var.engine_version, "0.0"))) >= 2
    error_message = "MySQL and MariaDB versions must include the minor release series, for example 8.4 or 11.4."
  }
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
  description = "Upper limit in GB for storage autoscaling"
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage > var.allocated_storage
    error_message = "max_allocated_storage must be greater than allocated_storage."
  }
}

variable "storage_type" {
  description = "Storage type (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.storage_type)
    error_message = "storage_type must be gp3, gp2, io1 or io2."
  }
}

variable "iops" {
  description = "Provisioned IOPS. Required for io1 and io2; optional for gp3 volumes of 400 GB or more"
  type        = number
  default     = null

  validation {
    condition     = !contains(["io1", "io2"], var.storage_type) || var.iops != null
    error_message = "iops must be set when storage_type is io1 or io2."
  }
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "app"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.db_name))
    error_message = "db_name must start with a letter and contain only letters, digits and underscores."
  }
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "dbadmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,15}$", var.db_username)) && !contains(["admin", "root", "postgres", "rdsadmin", "user"], lower(var.db_username))
    error_message = "db_username must be 1-16 letters, digits or underscores, start with a letter and not be a reserved name (admin, root, postgres, rdsadmin, user)."
  }
}

variable "multi_az" {
  description = "Deploy a standby instance in a second availability zone"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "backup_window" {
  description = "Daily backup window (UTC). Must not overlap the maintenance window"
  type        = string
  default     = "03:00-04:00"
}

variable "backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 1 and 35 days."
  }
}

variable "deletion_protection" {
  description = "Protect the database instance from deletion"
  type        = bool
  default     = true
}

variable "auto_minor_version_upgrade" {
  description = "Apply minor engine upgrades automatically during the maintenance window"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights. MySQL and MariaDB do not support it on micro and small burstable instance classes"
  type        = bool
  default     = true
}

variable "performance_insights_retention" {
  description = "Performance Insights retention in days (7, a multiple of 31 up to 713, or 731)"
  type        = number
  default     = 7
}

variable "enhanced_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 disables it)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.enhanced_monitoring_interval)
    error_message = "enhanced_monitoring_interval must be one of 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "cloudwatch_logs_exports" {
  description = "Log types exported to CloudWatch Logs. Null selects the engine's standard set (postgres: postgresql, upgrade; mysql and mariadb: error, slowquery)"
  type        = list(string)
  default     = null
}

variable "db_parameters" {
  description = "Parameters added to the parameter group on top of the TLS enforcement the module always sets"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

# ElastiCache Configuration
variable "enable_elasticache" {
  description = "Create an encrypted ElastiCache Redis replication group with an auth token"
  type        = bool
  default     = false
}

variable "cache_engine_version" {
  description = "Redis OSS engine version of the cache (7.x)"
  type        = string
  default     = "7.1"

  validation {
    condition     = can(regex("^7\\.[0-9]+$", var.cache_engine_version))
    error_message = "cache_engine_version must be a Redis OSS 7.x version such as 7.1."
  }
}

variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "cache_num_nodes" {
  description = "Number of cache nodes. Two or more enables automatic failover across availability zones"
  type        = number
  default     = 1

  validation {
    condition     = var.cache_num_nodes >= 1 && var.cache_num_nodes <= 6
    error_message = "cache_num_nodes must be between 1 and 6."
  }
}

variable "cache_snapshot_retention" {
  description = "Cache snapshot retention in days (0 disables snapshots)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
