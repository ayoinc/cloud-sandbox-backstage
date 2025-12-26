# -----------------------------------------------------------------------------
# AWS Storage Module - Variables
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
  description = "VPC ID for EFS"
  type        = string
  default     = null
}

# S3 Configuration
variable "bucket_suffix" {
  description = "Suffix for bucket name"
  type        = string
  default     = "data"
}

variable "enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects"
  type        = bool
  default     = false
}

variable "access_logging_bucket" {
  description = "Target bucket for access logging"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "S3 lifecycle rules"
  type = list(object({
    id                         = string
    enabled                    = bool
    prefix                     = string
    expiration_days            = optional(number)
    noncurrent_expiration_days = optional(number)
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    noncurrent_transitions = list(object({
      days          = number
      storage_class = string
    }))
  }))
  default = [
    {
      id                         = "archive-old-objects"
      enabled                    = true
      prefix                     = ""
      expiration_days            = null
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
  description = "CORS rules for S3 bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

# EFS Configuration
variable "enable_efs" {
  description = "Enable EFS file system"
  type        = bool
  default     = false
}

variable "efs_subnet_ids" {
  description = "Subnet IDs for EFS mount targets"
  type        = list(string)
  default     = []
}

variable "efs_allowed_security_groups" {
  description = "Security groups allowed to access EFS"
  type        = list(string)
  default     = []
}

variable "efs_performance_mode" {
  description = "EFS performance mode"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.efs_performance_mode)
    error_message = "Performance mode must be generalPurpose or maxIO."
  }
}

variable "efs_throughput_mode" {
  description = "EFS throughput mode"
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.efs_throughput_mode)
    error_message = "Throughput mode must be bursting, provisioned, or elastic."
  }
}

variable "efs_lifecycle_policy" {
  description = "EFS lifecycle policy for IA transition"
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "efs_enable_backup" {
  description = "Enable automatic EFS backups"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
