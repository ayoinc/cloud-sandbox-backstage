# -----------------------------------------------------------------------------
# GCP Storage Module - Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources (e.g., us-central1)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# Cloud Storage Bucket Configuration
# -----------------------------------------------------------------------------

variable "bucket_suffix" {
  description = "Suffix to append to the bucket name for uniqueness"
  type        = string
  default     = "data"
}

variable "storage_class" {
  description = "Storage class for the bucket"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE", "MULTI_REGIONAL", "REGIONAL"], var.storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE, MULTI_REGIONAL, REGIONAL."
  }
}

variable "enable_versioning" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow deletion of bucket even if it contains objects"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Lifecycle Rules
# -----------------------------------------------------------------------------

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    action_type                          = string           # Delete, SetStorageClass, AbortIncompleteMultipartUpload
    action_storage_class                 = optional(string) # Target storage class for SetStorageClass action
    condition_age_days                   = optional(number) # Age in days
    condition_created_before             = optional(string) # Date in RFC 3339 format
    condition_with_state                 = optional(string) # LIVE, ARCHIVED, ANY
    condition_matches_storage_class      = optional(list(string))
    condition_num_newer_versions         = optional(number)
    condition_days_since_noncurrent_time = optional(number)
  }))
  default = [
    {
      action_type                          = "SetStorageClass"
      action_storage_class                 = "NEARLINE"
      condition_age_days                   = 30
      condition_created_before             = null
      condition_with_state                 = null
      condition_matches_storage_class      = ["STANDARD"]
      condition_num_newer_versions         = null
      condition_days_since_noncurrent_time = null
    },
    {
      action_type                          = "SetStorageClass"
      action_storage_class                 = "COLDLINE"
      condition_age_days                   = 90
      condition_created_before             = null
      condition_with_state                 = null
      condition_matches_storage_class      = ["NEARLINE"]
      condition_num_newer_versions         = null
      condition_days_since_noncurrent_time = null
    },
    {
      action_type                          = "Delete"
      action_storage_class                 = null
      condition_age_days                   = null
      condition_created_before             = null
      condition_with_state                 = "ARCHIVED"
      condition_matches_storage_class      = null
      condition_num_newer_versions         = 3
      condition_days_since_noncurrent_time = null
    }
  ]
}

# -----------------------------------------------------------------------------
# Encryption Configuration
# -----------------------------------------------------------------------------

variable "kms_key_name" {
  description = "Cloud KMS key name for bucket encryption (optional). Format: projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{key}"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------

variable "cors_config" {
  description = "CORS configuration for the bucket (optional)"
  type = object({
    origins          = list(string)
    methods          = list(string)
    response_headers = list(string)
    max_age_seconds  = number
  })
  default = null
}

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------

variable "logging_bucket" {
  description = "Name of the bucket to store access logs (optional)"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for log object names (optional)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Retention Policy
# -----------------------------------------------------------------------------

variable "retention_period_seconds" {
  description = "Retention period in seconds (optional)"
  type        = number
  default     = null
}

variable "retention_policy_is_locked" {
  description = "Whether the retention policy is locked"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------

variable "bucket_viewers" {
  description = "List of members to grant storage.objectViewer role (e.g., user:email@example.com, serviceAccount:sa@project.iam.gserviceaccount.com)"
  type        = list(string)
  default     = []
}

variable "bucket_admins" {
  description = "List of members to grant storage.objectAdmin role"
  type        = list(string)
  default     = []
}

variable "bucket_creators" {
  description = "List of members to grant storage.objectCreator role"
  type        = list(string)
  default     = []
}

variable "custom_iam_bindings" {
  description = "Custom IAM bindings for the bucket"
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Filestore Configuration (NFS Storage)
# -----------------------------------------------------------------------------

variable "enable_filestore" {
  description = "Enable Cloud Filestore instance for NFS storage"
  type        = bool
  default     = false
}

variable "filestore_tier" {
  description = "Filestore service tier"
  type        = string
  default     = "BASIC_HDD"

  validation {
    condition     = contains(["BASIC_HDD", "BASIC_SSD", "HIGH_SCALE_SSD", "ENTERPRISE", "ZONAL", "REGIONAL"], var.filestore_tier)
    error_message = "Filestore tier must be one of: BASIC_HDD, BASIC_SSD, HIGH_SCALE_SSD, ENTERPRISE, ZONAL, REGIONAL."
  }
}

variable "filestore_capacity_gb" {
  description = "Capacity of the Filestore instance in GB"
  type        = number
  default     = 1024

  validation {
    condition     = var.filestore_capacity_gb >= 1024
    error_message = "Filestore capacity must be at least 1024 GB for BASIC tiers."
  }
}

variable "filestore_zone" {
  description = "Zone for Filestore instance. If not specified, defaults to region-a"
  type        = string
  default     = null
}

variable "filestore_share_name" {
  description = "Name of the file share"
  type        = string
  default     = "share"
}

variable "filestore_network" {
  description = "VPC network name for Filestore instance"
  type        = string
  default     = "default"
}

variable "filestore_reserved_ip_range" {
  description = "Reserved IP range for Filestore in CIDR notation (optional)"
  type        = string
  default     = null
}

variable "filestore_nfs_export_options" {
  description = "NFS export options for Filestore"
  type = list(object({
    ip_ranges   = list(string)
    access_mode = string # READ_ONLY, READ_WRITE
    squash_mode = string # NO_ROOT_SQUASH, ROOT_SQUASH
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
