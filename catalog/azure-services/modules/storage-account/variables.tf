################################################################################
# Azure Storage Account Variables
################################################################################

variable "storage_account_name" {
  description = "Name of the storage account (3-24 chars, lowercase alphanumeric)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "ZRS"
}

variable "account_kind" {
  description = "Account kind (StorageV2, Storage, BlobStorage, BlockBlobStorage, FileStorage)"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Access tier for BlobStorage accounts (Hot or Cool)"
  type        = string
  default     = "Hot"
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "allow_public_access" {
  description = "Allow public access to blobs"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key"
  type        = bool
  default     = true
}

variable "blob_properties" {
  description = "Blob properties configuration"
  type        = any
  default     = null
}

variable "network_rules" {
  description = "Network rules for the storage account"
  type        = any
  default     = null
}

variable "identity_type" {
  description = "Identity type (SystemAssigned, UserAssigned, SystemAssigned,UserAssigned)"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "User assigned identity IDs"
  type        = list(string)
  default     = []
}

variable "customer_managed_key" {
  description = "Customer managed key configuration"
  type        = any
  default     = null
}

variable "containers" {
  description = "List of blob containers to create"
  type        = list(any)
  default     = []
}

variable "lifecycle_rules" {
  description = "Lifecycle management rules"
  type        = list(any)
  default     = []
}

variable "private_endpoint_config" {
  description = "Private endpoint configuration"
  type        = any
  default     = null
}

variable "diagnostic_settings" {
  description = "Diagnostic settings configuration"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
