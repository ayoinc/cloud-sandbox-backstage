# =============================================================================
# AZURE STORAGE ACCOUNT MODULE
# =============================================================================
# Creates Azure Storage Account with containers, file shares, queues, tables
# Supports blob, file, queue, table, and data lake storage
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Access tier for BlobStorage, FileStorage, StorageV2 (Hot, Cool)"
  type        = string
  default     = "Hot"
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "enable_https_traffic_only" {
  description = "Only allow HTTPS traffic"
  type        = bool
  default     = true
}

variable "allow_nested_items_to_be_public" {
  description = "Allow public access to blobs"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key authentication"
  type        = bool
  default     = true
}

variable "is_hns_enabled" {
  description = "Enable hierarchical namespace (Data Lake Gen2)"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "enable_soft_delete" {
  description = "Enable soft delete for blobs and containers"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted items"
  type        = number
  default     = 7
}

variable "containers" {
  description = "Map of containers to create"
  type = map(object({
    access_type = optional(string, "private")
  }))
  default = {}
}

variable "file_shares" {
  description = "Map of file shares to create"
  type = map(object({
    quota = optional(number, 50)
    tier  = optional(string, "TransactionOptimized")
  }))
  default = {}
}

variable "queues" {
  description = "List of queue names to create"
  type        = list(string)
  default     = []
}

variable "tables" {
  description = "List of table names to create"
  type        = list(string)
  default     = []
}

variable "network_rules" {
  description = "Network rules configuration"
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Storage account names must be 3-24 chars, lowercase alphanumeric only
  storage_account_name = lower(replace("st${var.project}${var.environment}${substr(md5("${var.project}-${var.environment}-${var.location}"), 0, 8)}", "/[^a-z0-9]/", ""))

  # Environment-specific configuration
  env_config = {
    dev = {
      replication_type   = "LRS"
      soft_delete_days   = 7
      versioning_enabled = false
    }
    staging = {
      replication_type   = "ZRS"
      soft_delete_days   = 14
      versioning_enabled = true
    }
    prod = {
      replication_type   = "GRS"
      soft_delete_days   = 30
      versioning_enabled = true
    }
  }

  config = lookup(local.env_config, var.environment, local.env_config["dev"])
}

# -----------------------------------------------------------------------------
# Storage Account
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                            = substr(local.storage_account_name, 0, 24)
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  account_kind                    = var.account_kind
  access_tier                     = var.access_tier
  min_tls_version                 = var.min_tls_version
  enable_https_traffic_only       = var.enable_https_traffic_only
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled
  is_hns_enabled                  = var.is_hns_enabled

  blob_properties {
    versioning_enabled = var.enable_versioning

    dynamic "delete_retention_policy" {
      for_each = var.enable_soft_delete ? [1] : []
      content {
        days = var.soft_delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.enable_soft_delete ? [1] : []
      content {
        days = var.soft_delete_retention_days
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Blob Containers
# -----------------------------------------------------------------------------

resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.access_type
}

# -----------------------------------------------------------------------------
# File Shares
# -----------------------------------------------------------------------------

resource "azurerm_storage_share" "shares" {
  for_each = var.file_shares

  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
  quota                = each.value.quota
  access_tier          = each.value.tier
}

# -----------------------------------------------------------------------------
# Queues
# -----------------------------------------------------------------------------

resource "azurerm_storage_queue" "queues" {
  for_each = toset(var.queues)

  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# -----------------------------------------------------------------------------
# Tables
# -----------------------------------------------------------------------------

resource "azurerm_storage_table" "tables" {
  for_each = toset(var.tables)

  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# -----------------------------------------------------------------------------
# Private Endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "blob" {
  count = var.enable_private_endpoint && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${azurerm_storage_account.main.name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.main.name}-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file endpoint"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "primary_queue_endpoint" {
  description = "Primary queue endpoint"
  value       = azurerm_storage_account.main.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "Primary table endpoint"
  value       = azurerm_storage_account.main.primary_table_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "container_ids" {
  description = "Map of container names to IDs"
  value       = { for k, v in azurerm_storage_container.containers : k => v.id }
}

output "file_share_ids" {
  description = "Map of file share names to IDs"
  value       = { for k, v in azurerm_storage_share.shares : k => v.id }
}
