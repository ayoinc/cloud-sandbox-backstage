variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "creation_token" {
  description = "A unique name used as a reference when creating the EFS file system"
  type        = string
  default     = null
}

variable "encrypted" {
  description = "Whether to enable encryption at rest for the EFS file system"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use for encryption. If not specified, AWS managed key will be used"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "The file system performance mode. Valid values: generalPurpose, maxIO"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Valid values: bursting, provisioned, elastic"
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Throughput mode must be 'bursting', 'provisioned', or 'elastic'."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision. Only applicable when throughput_mode is set to provisioned"
  type        = number
  default     = null
}

variable "lifecycle_policies" {
  description = "List of lifecycle policies for the file system"
  type = list(object({
    transition_to_ia                    = optional(string)
    transition_to_primary_storage_class = optional(string)
  }))
  default = []
}

variable "subnet_ids" {
  description = "List of subnet IDs for mount targets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with mount targets"
  type        = list(string)
}

variable "enable_backup" {
  description = "Whether to enable automatic backups for the EFS file system"
  type        = bool
  default     = true
}

variable "file_system_policy" {
  description = "JSON formatted file system policy to attach to the EFS file system"
  type        = string
  default     = null
}

variable "access_points" {
  description = "List of access point configurations"
  type = list(object({
    name                = string
    root_directory_path = string
    posix_user = optional(object({
      gid            = number
      uid            = number
      secondary_gids = optional(list(number))
    }))
    root_directory_creation_info = optional(object({
      owner_gid   = number
      owner_uid   = number
      permissions = string
    }))
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
