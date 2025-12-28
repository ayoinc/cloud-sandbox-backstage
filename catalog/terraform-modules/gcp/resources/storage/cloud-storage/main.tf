# =============================================================================
# GCP CLOUD STORAGE MODULE
# =============================================================================
# Creates Cloud Storage bucket with security and lifecycle policies
# Follows Google Cloud best practices
# Provider version: ~> 5.0
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "name" {
  description = "Bucket name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Bucket location"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "uniform_bucket_level_access" {
  description = "Enable uniform bucket-level access"
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Public access prevention (enforced or inherited)"
  type        = string
  default     = "enforced"
}

variable "encryption_key" {
  description = "Customer-managed encryption key"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                        = optional(number)
      created_before             = optional(string)
      with_state                 = optional(string)
      matches_storage_class      = optional(list(string))
      num_newer_versions         = optional(number)
      days_since_noncurrent_time = optional(number)
    })
  }))
  default = []
}

variable "cors" {
  description = "CORS configuration"
  type = list(object({
    origin          = list(string)
    method          = list(string)
    response_header = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

variable "logging_bucket" {
  description = "Bucket for access logs"
  type        = string
  default     = null
}

variable "retention_policy_days" {
  description = "Retention policy in days (0 to disable)"
  type        = number
  default     = 0
}

variable "iam_bindings" {
  description = "IAM bindings for the bucket"
  type = map(object({
    role    = string
    members = list(string)
  }))
  default = {}
}

variable "labels" {
  description = "Labels to apply to the bucket"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  bucket_name = "${var.name}-${var.environment}-${var.project_id}"

  common_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  # Default lifecycle rules for cost optimization
  default_lifecycle_rules = var.versioning_enabled ? [
    {
      action = {
        type = "Delete"
      }
      condition = {
        num_newer_versions = 5
        with_state         = "ARCHIVED"
      }
    }
  ] : []

  all_lifecycle_rules = concat(local.default_lifecycle_rules, var.lifecycle_rules)
}

# -----------------------------------------------------------------------------
# Cloud Storage Bucket
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "main" {
  project       = var.project_id
  name          = local.bucket_name
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  uniform_bucket_level_access = var.uniform_bucket_level_access
  public_access_prevention    = var.public_access_prevention

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "encryption" {
    for_each = var.encryption_key != null ? [1] : []
    content {
      default_kms_key_name = var.encryption_key
    }
  }

  dynamic "lifecycle_rule" {
    for_each = local.all_lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
      condition {
        age                        = lifecycle_rule.value.condition.age
        created_before             = lifecycle_rule.value.condition.created_before
        with_state                 = lifecycle_rule.value.condition.with_state
        matches_storage_class      = lifecycle_rule.value.condition.matches_storage_class
        num_newer_versions         = lifecycle_rule.value.condition.num_newer_versions
        days_since_noncurrent_time = lifecycle_rule.value.condition.days_since_noncurrent_time
      }
    }
  }

  dynamic "cors" {
    for_each = var.cors
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  dynamic "logging" {
    for_each = var.logging_bucket != null ? [1] : []
    content {
      log_bucket        = var.logging_bucket
      log_object_prefix = "${local.bucket_name}/"
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy_days > 0 ? [1] : []
    content {
      retention_period = var.retention_policy_days * 86400 # Convert days to seconds
    }
  }

  labels = local.common_labels
}

# -----------------------------------------------------------------------------
# IAM Bindings
# -----------------------------------------------------------------------------

resource "google_storage_bucket_iam_binding" "bindings" {
  for_each = var.iam_bindings

  bucket  = google_storage_bucket.main.name
  role    = each.value.role
  members = each.value.members
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "bucket_id" {
  description = "Bucket ID"
  value       = google_storage_bucket.main.id
}

output "bucket_name" {
  description = "Bucket name"
  value       = google_storage_bucket.main.name
}

output "bucket_url" {
  description = "Bucket URL"
  value       = google_storage_bucket.main.url
}

output "bucket_self_link" {
  description = "Bucket self link"
  value       = google_storage_bucket.main.self_link
}
