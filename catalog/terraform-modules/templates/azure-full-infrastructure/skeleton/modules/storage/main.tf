# =============================================================================
# STORAGE MODULE
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

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }
variable "account_tier" { type = string; default = "Standard" }
variable "account_replication_type" { type = string; default = "LRS" }
variable "enable_versioning" { type = bool; default = true }
variable "enable_soft_delete" { type = bool; default = true }
variable "subnet_ids" { type = list(string); default = [] }

locals {
  # Storage account names must be 3-24 chars, lowercase alphanumeric only
  storage_account_name = lower(replace("st${var.project}${var.environment}", "-", ""))
}

resource "azurerm_storage_account" "main" {
  name                     = substr(local.storage_account_name, 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  blob_properties {
    versioning_enabled = var.enable_versioning
    delete_retention_policy {
      days = var.enable_soft_delete ? 7 : 0
    }
    container_delete_retention_policy {
      days = var.enable_soft_delete ? 7 : 0
    }
  }

  network_rules {
    default_action             = length(var.subnet_ids) > 0 ? "Deny" : "Allow"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.subnet_ids
  }

  tags = var.tags
}

output "storage_account_id" { value = azurerm_storage_account.main.id }
output "storage_account_name" { value = azurerm_storage_account.main.name }
output "primary_blob_endpoint" { value = azurerm_storage_account.main.primary_blob_endpoint }
output "primary_access_key" { value = azurerm_storage_account.main.primary_access_key; sensitive = true }
