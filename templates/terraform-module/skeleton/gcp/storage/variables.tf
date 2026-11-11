variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.project_name))
    error_message = "project_name must start with a lowercase letter and contain only lowercase letters, digits and hyphens (max 63 characters)."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,7}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits and start with a letter."
  }
}

variable "project_id" {
  description = "ID of the Google Cloud project that owns the resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID (6-30 lowercase letters, digits or hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region for regional resources."
  type        = string
}

variable "labels" {
  description = "Labels applied to every resource that supports them."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "kms_key_id" {
  description = "ID of a Cloud KMS key that encrypts the bucket. Null uses Google-managed encryption. The Cloud Storage service agent must be allowed to use the key (see grant_kms_access)."
  type        = string
  default     = null
}

variable "grant_kms_access" {
  description = "Grant the project's Cloud Storage service agent encrypt/decrypt access to kms_key_id. Leave false when the owner of the key already grants it."
  type        = bool
  default     = false
}

variable "bucket_suffix" {
  description = "Purpose of the bucket, used in its name between the prefix and the random suffix."
  type        = string
  default     = "data"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,18}[a-z0-9])?$", var.bucket_suffix))
    error_message = "bucket_suffix must be 1-20 lowercase letters, digits or hyphens and must not start or end with a hyphen."
  }
}

variable "storage_class" {
  description = "Default storage class of the bucket."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class must be STANDARD, NEARLINE, COLDLINE or ARCHIVE."
  }
}

variable "enable_versioning" {
  description = "Keep noncurrent object versions."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Days deleted objects stay recoverable. 0 disables soft delete; otherwise 7 to 90."
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days == 0 || (var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90)
    error_message = "soft_delete_retention_days must be 0 or between 7 and 90."
  }
}

variable "force_destroy" {
  description = "Delete all objects when the bucket is destroyed."
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Object lifecycle rules. action is Delete, SetStorageClass or AbortIncompleteMultipartUpload; storage_class is required for SetStorageClass; with_state is LIVE, ARCHIVED or ANY."
  type = list(object({
    action                = string
    storage_class         = optional(string)
    age_days              = optional(number)
    num_newer_versions    = optional(number)
    days_since_noncurrent = optional(number)
    with_state            = optional(string)
    matches_prefix        = optional(list(string))
  }))
  default = [
    {
      action                = "Delete"
      days_since_noncurrent = 90
      with_state            = "ARCHIVED"
    },
  ]
  nullable = false

  validation {
    condition = alltrue([
      for r in var.lifecycle_rules :
      contains(["Delete", "SetStorageClass", "AbortIncompleteMultipartUpload"], r.action) &&
      (r.action != "SetStorageClass" || r.storage_class != null)
    ])
    error_message = "Each rule needs a valid action, and SetStorageClass rules need storage_class."
  }
}

variable "cors_config" {
  description = "CORS configuration for browser access to the bucket. Null disables CORS."
  type = object({
    origins          = list(string)
    methods          = list(string)
    response_headers = optional(list(string), [])
    max_age_seconds  = optional(number, 3600)
  })
  default = null
}

variable "logging_bucket" {
  description = "Name of an existing bucket that receives access logs for this bucket. Null disables access logging."
  type        = string
  default     = null
}

variable "retention_period_seconds" {
  description = "Minimum age in seconds before objects can be deleted or replaced. Null sets no retention policy."
  type        = number
  default     = null

  validation {
    condition     = var.retention_period_seconds == null || try(var.retention_period_seconds > 0, false)
    error_message = "retention_period_seconds must be greater than 0."
  }
}

variable "retention_policy_is_locked" {
  description = "Lock the retention policy. Locking is permanent and cannot be undone."
  type        = bool
  default     = false
}

variable "bucket_viewers" {
  description = "IAM members granted roles/storage.objectViewer on the bucket."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for m in var.bucket_viewers : can(regex("^(user|group|serviceAccount|domain|principal|principalSet):.+", m))])
    error_message = "Members must use an IAM principal prefix such as user:, group: or serviceAccount:. Public principals are not allowed."
  }
}

variable "bucket_creators" {
  description = "IAM members granted roles/storage.objectCreator on the bucket."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for m in var.bucket_creators : can(regex("^(user|group|serviceAccount|domain|principal|principalSet):.+", m))])
    error_message = "Members must use an IAM principal prefix such as user:, group: or serviceAccount:. Public principals are not allowed."
  }
}

variable "bucket_writers" {
  description = "IAM members granted roles/storage.objectUser on the bucket (read, create, replace and delete objects)."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for m in var.bucket_writers : can(regex("^(user|group|serviceAccount|domain|principal|principalSet):.+", m))])
    error_message = "Members must use an IAM principal prefix such as user:, group: or serviceAccount:. Public principals are not allowed."
  }
}

variable "enable_filestore" {
  description = "Create a Filestore instance that exports an NFS share."
  type        = bool
  default     = false
}

variable "filestore_tier" {
  description = "Filestore service tier."
  type        = string
  default     = "BASIC_HDD"

  validation {
    condition     = contains(["BASIC_HDD", "BASIC_SSD", "ZONAL", "REGIONAL", "ENTERPRISE"], var.filestore_tier)
    error_message = "filestore_tier must be BASIC_HDD, BASIC_SSD, ZONAL, REGIONAL or ENTERPRISE."
  }
}

variable "filestore_capacity_gb" {
  description = "Capacity of the NFS share in GiB. The minimum depends on the tier (1024 for BASIC_HDD, 2560 for BASIC_SSD)."
  type        = number
  default     = 1024

  validation {
    condition     = var.filestore_capacity_gb >= 1024
    error_message = "filestore_capacity_gb must be at least 1024."
  }
}

variable "filestore_zone" {
  description = "Location of the Filestore instance: a zone for BASIC and ZONAL tiers, a region for REGIONAL and ENTERPRISE. Null uses zone a of the region."
  type        = string
  default     = null
}

variable "filestore_share_name" {
  description = "Name of the NFS share."
  type        = string
  default     = "share"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,15}$", var.filestore_share_name))
    error_message = "filestore_share_name must start with a lowercase letter and contain up to 16 lowercase letters, digits or underscores."
  }
}

variable "filestore_network" {
  description = "Name of the VPC the Filestore instance attaches to. Null uses the project's default network."
  type        = string
  default     = null
}

variable "filestore_allowed_ip_ranges" {
  description = "Client ranges allowed to mount the share read-write with root squash. Null allows every client in the VPC."
  type        = list(string)
  default     = null

  validation {
    condition     = var.filestore_allowed_ip_ranges == null || try(length(var.filestore_allowed_ip_ranges) > 0 && alltrue([for r in var.filestore_allowed_ip_ranges : can(cidrhost(r, 0))]), false)
    error_message = "filestore_allowed_ip_ranges must be null or a non-empty list of valid CIDR blocks."
  }
}
