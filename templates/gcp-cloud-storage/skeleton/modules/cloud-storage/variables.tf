# =============================================================================
# GCP Cloud Storage Module - Variables
# =============================================================================
# =============================================================================

variable "name" {
  description = "Name used in resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "The name must start with a letter and contain only lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "project_id" {
  description = "Google Cloud project that holds the resources"
  type        = string
}

variable "owner" {
  description = "Owner of the resources, added as a label"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Additional labels for all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Bucket
# -----------------------------------------------------------------------------

variable "location" {
  description = "Bucket location: a region such as europe-west1, or a multi-region (US, EU, ASIA). It cannot be changed after creation"
  type        = string
}

variable "storage_class" {
  description = "Default storage class of objects: STANDARD, NEARLINE, COLDLINE or ARCHIVE"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "The storage class must be STANDARD, NEARLINE, COLDLINE or ARCHIVE."
  }
}

variable "force_destroy" {
  description = "Delete the objects when the bucket is destroyed. Off, a bucket that still holds objects cannot be destroyed"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Data Protection
# -----------------------------------------------------------------------------

variable "versioning_enabled" {
  description = "Keep previous versions of overwritten and deleted objects"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Days a deleted object or bucket can be restored: 0 to switch soft delete off, or 7 to 90"
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days == 0 || (var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90)
    error_message = "The soft delete retention must be 0 or between 7 and 90 days."
  }
}

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

variable "nearline_after_days" {
  description = "Age in days at which objects move to NEARLINE; null never moves them"
  type        = number
  default     = null
}

variable "coldline_after_days" {
  description = "Age in days at which objects move to COLDLINE; null never moves them"
  type        = number
  default     = null
}

variable "archive_after_days" {
  description = "Age in days at which objects move to ARCHIVE; null never moves them"
  type        = number
  default     = null
}

variable "expire_after_days" {
  description = "Age in days at which objects are deleted; null keeps them forever"
  type        = number
  default     = null
}

variable "noncurrent_versions_to_keep" {
  description = "Previous versions kept for each object; older ones are deleted"
  type        = number
  default     = 3
}

variable "noncurrent_version_retention_days" {
  description = "Days a previous version is kept at most"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Encryption
# -----------------------------------------------------------------------------

variable "customer_managed_encryption" {
  description = "Encrypt objects with a Cloud KMS key created here, in the bucket location, instead of a Google-managed key"
  type        = bool
  default     = false
}

variable "kms_key_name" {
  description = "Existing Cloud KMS key (projects/.../cryptoKeys/...) in the bucket location to encrypt objects with. Takes precedence over customer_managed_encryption"
  type        = string
  default     = null
}

variable "kms_key_rotation_period" {
  description = "Rotation period of the created key, in seconds with an s suffix"
  type        = string
  default     = "7776000s"
}

# -----------------------------------------------------------------------------
# Access
# -----------------------------------------------------------------------------

variable "object_viewers" {
  description = "IAM members that may read objects, such as serviceAccount:name@project.iam.gserviceaccount.com or group:team@domain"
  type        = set(string)
  default     = []
}

variable "object_users" {
  description = "IAM members that may read, write and delete objects"
  type        = set(string)
  default     = []
}

variable "object_admins" {
  description = "IAM members with full control of objects, including their versions"
  type        = set(string)
  default     = []
}

variable "enable_apis" {
  description = "Enable the Google Cloud APIs the bucket needs. Switch off when the pipeline may not manage services"
  type        = bool
  default     = true
}
