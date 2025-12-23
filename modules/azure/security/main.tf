# Azure Security Module
# Reusable module for creating Azure Key Vault, Managed Identities, and related security resources

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "this" {
  for_each = var.key_vaults

  name                            = each.key
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = each.value.sku_name
  enabled_for_deployment          = each.value.enabled_for_deployment
  enabled_for_disk_encryption     = each.value.enabled_for_disk_encryption
  enabled_for_template_deployment = each.value.enabled_for_template_deployment
  enable_rbac_authorization       = each.value.enable_rbac_authorization
  purge_protection_enabled        = each.value.purge_protection_enabled
  soft_delete_retention_days      = each.value.soft_delete_retention_days
  public_network_access_enabled   = each.value.public_network_access_enabled

  dynamic "network_acls" {
    for_each = each.value.network_acls != null ? [each.value.network_acls] : []
    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

# Key Vault Access Policy (only when RBAC is disabled)
resource "azurerm_key_vault_access_policy" "this" {
  for_each = var.key_vault_access_policies

  key_vault_id = azurerm_key_vault.this[each.value.key_vault_key].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
  storage_permissions     = each.value.storage_permissions
}

# Key Vault Secret
resource "azurerm_key_vault_secret" "this" {
  for_each = var.key_vault_secrets

  name            = each.key
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.this[each.value.key_vault_key].id
  content_type    = each.value.content_type
  expiration_date = each.value.expiration_date
  not_before_date = each.value.not_before_date

  tags = var.tags

  depends_on = [azurerm_key_vault_access_policy.this]
}

# Key Vault Key
resource "azurerm_key_vault_key" "this" {
  for_each = var.key_vault_keys

  name            = each.key
  key_vault_id    = azurerm_key_vault.this[each.value.key_vault_key].id
  key_type        = each.value.key_type
  key_size        = each.value.key_size
  key_opts        = each.value.key_opts
  expiration_date = each.value.expiration_date
  not_before_date = each.value.not_before_date

  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []
    content {
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry

      dynamic "automatic" {
        for_each = rotation_policy.value.automatic != null ? [rotation_policy.value.automatic] : []
        content {
          time_after_creation = automatic.value.time_after_creation
          time_before_expiry  = automatic.value.time_before_expiry
        }
      }
    }
  }

  tags = var.tags

  depends_on = [azurerm_key_vault_access_policy.this]
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "this" {
  for_each = var.user_assigned_identities

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Role Assignment
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id != null ? each.value.principal_id : azurerm_user_assigned_identity.this[each.value.identity_key].principal_id
  principal_type       = each.value.principal_type
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  for_each = var.key_vault_private_endpoints

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "${each.key}-connection"
    private_connection_resource_id = azurerm_key_vault.this[each.value.key_vault_key].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [each.value.private_dns_zone_id]
    }
  }

  tags = var.tags
}
