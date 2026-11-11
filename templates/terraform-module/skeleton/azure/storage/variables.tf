# -----------------------------------------------------------------------------
# Azure Storage Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 2-40 characters of lowercase letters, numbers and hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.environment))
    error_message = "Environment must be 2-12 lowercase letters or numbers and start with a letter."
  }
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

variable "account_kind" {
  description = "Storage account kind: StorageV2 (Standard tier), BlockBlobStorage or FileStorage (Premium tier)"
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["StorageV2", "BlockBlobStorage", "FileStorage"], var.account_kind)
    error_message = "Account kind must be StorageV2, BlockBlobStorage or FileStorage."
  }
}

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

variable "enable_infrastructure_encryption" {
  description = "Add a second layer of encryption at rest with platform-managed keys. Changing this recreates the account"
  type        = bool
  default     = true
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
  description = "List of private blob containers to create"
  type        = list(string)
  nullable    = false
  default     = ["data"]

  validation {
    condition     = alltrue([for name in var.container_names : can(regex("^[a-z0-9]([a-z0-9]|-[a-z0-9]){2,62}$", name))])
    error_message = "Container names must be 3-63 characters of lowercase letters, numbers and single hyphens, starting and ending with a letter or number."
  }
}

# -----------------------------------------------------------------------------
# Lifecycle Rules
# -----------------------------------------------------------------------------

variable "lifecycle_rules" {
  description = "Storage lifecycle management rules. An empty prefix_match applies the rule to every blob"
  type = list(object({
    name                                 = string
    enabled                              = optional(bool, true)
    prefix_match                         = optional(list(string), [])
    blob_types                           = optional(list(string), ["blockBlob"])
    base_blob_tier_to_cool_after_days    = optional(number)
    base_blob_tier_to_archive_after_days = optional(number)
    base_blob_delete_after_days          = optional(number)
    snapshot_delete_after_days           = optional(number)
    version_delete_after_days            = optional(number)
  }))
  nullable = false
  default = [
    {
      name                                 = "archive-old-blobs"
      base_blob_tier_to_cool_after_days    = 30
      base_blob_tier_to_archive_after_days = 90
      snapshot_delete_after_days           = 30
      version_delete_after_days            = 90
    }
  ]

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules :
      rule.base_blob_tier_to_cool_after_days != null || rule.base_blob_tier_to_archive_after_days != null || rule.base_blob_delete_after_days != null || rule.snapshot_delete_after_days != null || rule.version_delete_after_days != null
    ])
    error_message = "Every lifecycle rule must set at least one action."
  }

  validation {
    condition     = length(distinct(var.lifecycle_rules[*].name)) == length(var.lifecycle_rules)
    error_message = "Lifecycle rule names must be unique."
  }
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

variable "public_network_access_enabled" {
  description = "Keep the public endpoint available so that allowed_subnet_ids and allowed_ip_ranges can reach the account. Disable when the account is reached only through private endpoints"
  type        = bool
  default     = true
}

variable "network_default_action" {
  description = "Action for traffic that matches no network rule (Deny or Allow). Deny admits only the allowed subnets, IP ranges and trusted Azure services"
  type        = string
  nullable    = false
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "Network default action must be Allow or Deny."
  }
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access storage account (each needs the Microsoft.Storage service endpoint)"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "allowed_ip_ranges" {
  description = "List of public IP addresses or CIDR ranges allowed to access storage account"
  type        = list(string)
  nullable    = false
  default     = []
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for blob diagnostic settings. Null disables diagnostics"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  nullable    = false
  default     = {}
}
