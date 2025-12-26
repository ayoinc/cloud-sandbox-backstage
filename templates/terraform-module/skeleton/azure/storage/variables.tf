# -----------------------------------------------------------------------------
# Azure Storage Module - Variables
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# -----------------------------------------------------------------------------
# Storage Account Configuration
# -----------------------------------------------------------------------------

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "delete_retention_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
  default     = 7

  validation {
    condition     = var.delete_retention_days >= 1 && var.delete_retention_days <= 365
    error_message = "Delete retention days must be between 1 and 365."
  }
}

variable "container_delete_retention_days" {
  description = "Number of days to retain deleted containers"
  type        = number
  default     = 7

  validation {
    condition     = var.container_delete_retention_days >= 1 && var.container_delete_retention_days <= 365
    error_message = "Container delete retention days must be between 1 and 365."
  }
}

# -----------------------------------------------------------------------------
# Container Configuration
# -----------------------------------------------------------------------------

variable "container_names" {
  description = "List of storage container names to create"
  type        = list(string)
  default     = ["data"]
}

# -----------------------------------------------------------------------------
# Lifecycle Rules
# -----------------------------------------------------------------------------

variable "lifecycle_rules" {
  description = "Storage lifecycle management rules"
  type = list(object({
    name                                 = string
    enabled                              = bool
    prefix_match                         = list(string)
    blob_types                           = list(string)
    base_blob_tier_to_cool_after_days    = optional(number)
    base_blob_tier_to_archive_after_days = optional(number)
    base_blob_delete_after_days          = optional(number)
    snapshot_delete_after_days           = optional(number)
    version_delete_after_days            = optional(number)
  }))
  default = [
    {
      name                                 = "archive-old-blobs"
      enabled                              = true
      prefix_match                         = [""]
      blob_types                           = ["blockBlob"]
      base_blob_tier_to_cool_after_days    = 30
      base_blob_tier_to_archive_after_days = 90
      base_blob_delete_after_days          = null
      snapshot_delete_after_days           = 30
      version_delete_after_days            = 90
    }
  ]
}

# -----------------------------------------------------------------------------
# Azure File Share Configuration
# -----------------------------------------------------------------------------

variable "enable_file_share" {
  description = "Enable Azure Files share"
  type        = bool
  default     = false
}

variable "file_share_quota_gb" {
  description = "Maximum size of the file share in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.file_share_quota_gb >= 1 && var.file_share_quota_gb <= 102400
    error_message = "File share quota must be between 1 and 102400 GB."
  }
}

variable "file_share_access_tier" {
  description = "Access tier for the file share"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool", "TransactionOptimized", "Premium"], var.file_share_access_tier)
    error_message = "File share access tier must be Hot, Cool, TransactionOptimized, or Premium."
  }
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_default_action" {
  description = "Default action for network rules (Allow or Deny). Set to null to disable network rules."
  type        = string
  default     = null

  validation {
    condition     = var.network_default_action == null || contains(["Allow", "Deny"], var.network_default_action)
    error_message = "Network default action must be Allow, Deny, or null."
  }
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access storage account"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "List of public IP addresses or CIDR ranges allowed to access storage account"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
