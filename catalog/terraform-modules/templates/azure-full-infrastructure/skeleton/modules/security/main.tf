# =============================================================================
# SECURITY MODULE
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
variable "enable_soft_delete" { type = bool; default = true }
variable "soft_delete_retention_days" { type = number; default = 7 }
variable "enable_purge_protection" { type = bool; default = false }
variable "subnet_ids" { type = list(string); default = [] }

data "azurerm_client_config" "current" {}

locals {
  key_vault_name = "kv-${var.project}-${var.environment}"
}

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.enable_purge_protection
  
  enable_rbac_authorization = true

  network_acls {
    default_action             = length(var.subnet_ids) > 0 ? "Deny" : "Allow"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.subnet_ids
  }

  tags = var.tags
}

output "key_vault_id" { value = azurerm_key_vault.main.id }
output "key_vault_name" { value = azurerm_key_vault.main.name }
output "key_vault_uri" { value = azurerm_key_vault.main.vault_uri }
