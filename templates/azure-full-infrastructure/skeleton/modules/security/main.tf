# =============================================================================
# SECURITY MODULE FOR AZURE FULL INFRASTRUCTURE
# =============================================================================
# Creates Key Vault and Managed Identity
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

variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "enable_keyvault" {
  type    = bool
  default = true
}

variable "enable_managed_identity" {
  type    = bool
  default = true
}

variable "keyvault_sku" {
  type    = string
  default = "standard"
}

variable "enable_rbac_authorization" {
  type    = bool
  default = true
}

variable "soft_delete_retention_days" {
  type    = number
  default = 90
}

variable "purge_protection_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Managed Identity
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "main" {
  count = var.enable_managed_identity ? 1 : 0

  name                = "${var.name_prefix}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  count = var.enable_keyvault ? 1 : 0

  name                       = replace("${var.name_prefix}-kv", "-", "")
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = var.keyvault_sku
  enable_rbac_authorization  = var.enable_rbac_authorization
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  tags                       = var.tags
}

# Grant Managed Identity access to Key Vault
resource "azurerm_role_assignment" "keyvault_secrets" {
  count = var.enable_keyvault && var.enable_managed_identity ? 1 : 0

  scope                = azurerm_key_vault.main[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.main[0].principal_id
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "key_vault_id" {
  value = var.enable_keyvault ? azurerm_key_vault.main[0].id : null
}

output "key_vault_uri" {
  value = var.enable_keyvault ? azurerm_key_vault.main[0].vault_uri : null
}

output "key_vault_name" {
  value = var.enable_keyvault ? azurerm_key_vault.main[0].name : null
}

output "managed_identity_id" {
  value = var.enable_managed_identity ? azurerm_user_assigned_identity.main[0].id : null
}

output "managed_identity_principal_id" {
  value = var.enable_managed_identity ? azurerm_user_assigned_identity.main[0].principal_id : null
}

output "managed_identity_client_id" {
  value = var.enable_managed_identity ? azurerm_user_assigned_identity.main[0].client_id : null
}
