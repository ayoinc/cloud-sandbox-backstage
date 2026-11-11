# -----------------------------------------------------------------------------
# AWS Storage Module - Variables
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

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the bucket and the EFS file system. Null uses S3-managed keys (SSE-S3) and the AWS managed EFS key"
  type        = string
  default     = null
}

# S3 Configuration
variable "bucket_suffix" {
  description = "Purpose suffix appended to the bucket name"
  type        = string
  default     = "data"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,18}[a-z0-9]$", var.bucket_suffix))
    error_message = "bucket_suffix must be 2-20 lowercase letters, digits or hyphens and must not start or end with a hyphen."
  }
}

variable "enable_versioning" {
  description = "Enable S3 object versioning (Suspended when false)"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow the bucket to be destroyed while it still contains objects"
  type        = bool
  default     = false
}

variable "access_logging_bucket" {
  description = "Name of an existing bucket that receives S3 server access logs. Null disables access logging"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "S3 lifecycle rules. An empty prefix applies the rule to the whole bucket"
  type = list(object({
    id                         = string
    enabled                    = optional(bool, true)
    prefix                     = optional(string, "")
    expiration_days            = optional(number)
    noncurrent_expiration_days = optional(number)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = [
    {
      id                         = "archive-old-objects"
      noncurrent_expiration_days = 90
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        }
      ]
      noncurrent_transitions = [
        {
          days          = 30
          storage_class = "GLACIER"
        }
      ]
    }
  ]
}

variable "cors_rules" {
  description = "CORS rules for the S3 bucket"
  type = list(object({
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

# EFS Configuration
variable "enable_efs" {
  description = "Create an encrypted EFS file system with mount targets and an access point. Requires vpc_id and efs_subnet_ids"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_efs || (var.vpc_id != null && length(var.efs_subnet_ids) > 0)
    error_message = "vpc_id and at least one entry in efs_subnet_ids must be set when enable_efs is true."
  }
}

variable "vpc_id" {
  description = "VPC ID the EFS security group is created in. Required when enable_efs is true"
  type        = string
  default     = null
}

variable "efs_subnet_ids" {
  description = "Subnet IDs (one per availability zone) that get an EFS mount target"
  type        = list(string)
  default     = []
}

variable "efs_allowed_security_groups" {
  description = "Security group IDs allowed to mount the EFS file system over NFS"
  type        = list(string)
  default     = []
}

variable "efs_performance_mode" {
  description = "EFS performance mode (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.efs_performance_mode)
    error_message = "efs_performance_mode must be generalPurpose or maxIO."
  }
}

variable "efs_throughput_mode" {
  description = "EFS throughput mode (bursting, elastic or provisioned)"
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.efs_throughput_mode)
    error_message = "efs_throughput_mode must be bursting, provisioned or elastic."
  }

  validation {
    condition     = !(var.efs_throughput_mode == "elastic" && var.efs_performance_mode == "maxIO")
    error_message = "Elastic throughput is only available with the generalPurpose performance mode."
  }
}

variable "efs_provisioned_throughput_mibps" {
  description = "Provisioned throughput in MiB/s. Only used, and then required, when efs_throughput_mode is provisioned"
  type        = number
  default     = null

  validation {
    condition     = var.efs_throughput_mode != "provisioned" || var.efs_provisioned_throughput_mibps != null
    error_message = "efs_provisioned_throughput_mibps must be set when efs_throughput_mode is provisioned."
  }
}

variable "efs_lifecycle_policy" {
  description = "Idle time after which EFS moves files to Infrequent Access (for example AFTER_30_DAYS). Null keeps files in standard storage"
  type        = string
  default     = "AFTER_30_DAYS"

  validation {
    condition = var.efs_lifecycle_policy == null || contains([
      "AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS",
      "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS"
    ], coalesce(var.efs_lifecycle_policy, "unset"))
    error_message = "efs_lifecycle_policy must be null or one of AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS."
  }
}

variable "efs_enable_backup" {
  description = "Enable automatic daily EFS backups through AWS Backup"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
