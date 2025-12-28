# =============================================================================
# AZURE KEY VAULT MODULE
# =============================================================================
# Creates Azure Key Vault with access policies, secrets, keys, and certificates
# Supports RBAC and access policy authorization
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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "sku_name" {
  description = "SKU name (standard, premium)"
  type        = string
  default     = "standard"
}

variable "enable_rbac_authorization" {
  description = "Use RBAC instead of access policies"
  type        = bool
  default     = true
}

variable "enabled_for_deployment" {
  description = "Allow VMs to retrieve certificates"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow ARM templates to retrieve secrets"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Days to retain soft-deleted items"
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "access_policies" {
  description = "List of access policies (ignored if RBAC is enabled)"
  type = list(object({
    object_id               = string
    tenant_id               = optional(string)
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = []
}

variable "network_acls" {
  description = "Network ACL configuration"
  type = object({
    bypass                     = optional(string, "AzureServices")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

variable "secrets" {
  description = "Map of secrets to create"
  type = map(object({
    value        = string
    content_type = optional(string, "text/plain")
    tags         = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
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
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Key Vault names must be 3-24 chars, alphanumeric and hyphens only
  key_vault_name = "kv-${var.project}-${var.environment}-${substr(md5("${var.project}-${var.environment}"), 0, 8)}"
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                            = substr(local.key_vault_name, 0, 24)
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.tenant_id
  sku_name                        = var.sku_name
  enable_rbac_authorization       = var.enable_rbac_authorization
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  public_network_access_enabled   = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  # Access policies (only if RBAC is disabled)
  dynamic "access_policy" {
    for_each = !var.enable_rbac_authorization ? var.access_policies : []
    content {
      tenant_id               = access_policy.value.tenant_id != null ? access_policy.value.tenant_id : var.tenant_id
      object_id               = access_policy.value.object_id
      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
      storage_permissions     = access_policy.value.storage_permissions
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Secrets
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id
  content_type = each.value.content_type
  tags         = each.value.tags
}

# -----------------------------------------------------------------------------
# Private Endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "vault" {
  count = var.enable_private_endpoint && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${azurerm_key_vault.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_key_vault.main.name}"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_tenant_id" {
  description = "Key Vault tenant ID"
  value       = azurerm_key_vault.main.tenant_id
}

output "secret_ids" {
  description = "Map of secret names to IDs"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_versions" {
  description = "Map of secret names to versions"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.version }
}
