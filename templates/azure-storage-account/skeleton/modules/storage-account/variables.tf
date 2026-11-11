# =============================================================================
# Azure Storage Account Module - Variables
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

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "description" {
  description = "Purpose of the resources, added as a tag"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources, added as a tag"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Account
# -----------------------------------------------------------------------------

variable "replication_type" {
  description = "Redundancy of the account: LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS"
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "The replication type must be LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS."
  }
}

variable "access_tier" {
  description = "Default access tier of blobs: Hot or Cool"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "The access tier must be Hot or Cool."
  }
}

variable "container_names" {
  description = "Private blob containers to create"
  type        = set(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Data Protection
# -----------------------------------------------------------------------------

variable "versioning_enabled" {
  description = "Keep previous versions of overwritten and deleted blobs"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Days a deleted blob or container can be restored"
  type        = number
  default     = 30

  validation {
    condition     = var.soft_delete_retention_days >= 1 && var.soft_delete_retention_days <= 365
    error_message = "The soft delete retention must be between 1 and 365 days."
  }
}

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

variable "cool_after_days" {
  description = "Days after the last modification when blobs move to the cool tier; null keeps them in place"
  type        = number
  default     = 30
}

variable "archive_after_days" {
  description = "Days after the last modification when blobs move to the archive tier; null never archives. Archiving needs LRS, GRS or RAGRS redundancy"
  type        = number
  default     = null

  validation {
    condition     = var.archive_after_days == null || contains(["LRS", "GRS", "RAGRS"], var.replication_type)
    error_message = "The archive tier is available only with LRS, GRS or RAGRS redundancy."
  }
}

variable "expire_after_days" {
  description = "Days after the last modification when blobs are deleted; null keeps them forever"
  type        = number
  default     = null
}

variable "noncurrent_version_retention_days" {
  description = "Days a previous version or snapshot is kept"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "public_network_access_enabled" {
  description = "Keep the public endpoint. It stays behind the firewall: only allowed_ip_ranges and allowed_subnet_ids get through"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Public IP addresses or CIDR ranges allowed through the firewall"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Subnets (with the Microsoft.Storage service endpoint) allowed through the firewall"
  type        = list(string)
  default     = []
}

variable "private_endpoint_subnet_id" {
  description = "Subnet for a private endpoint to the blob service; null creates none"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone privatelink.blob.core.windows.net to register the private endpoint in; null registers nothing"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Encryption, Access and Logging
# -----------------------------------------------------------------------------

variable "customer_managed_key" {
  description = "Key Vault key that encrypts the account instead of a platform-managed key. The vault must use Azure RBAC and have purge protection; give the versionless key ID to follow key rotation"
  type = object({
    key_vault_id     = string
    key_vault_key_id = string
  })
  default = null
}

variable "blob_data_contributor_principal_ids" {
  description = "Object IDs of users, groups or managed identities that may read and write blobs"
  type        = set(string)
  default     = []
}

variable "blob_data_reader_principal_ids" {
  description = "Object IDs of users, groups or managed identities that may read blobs"
  type        = set(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace that receives the blob read, write and delete logs; null sends none"
  type        = string
  default     = null
}
