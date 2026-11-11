# =============================================================================
# Azure Key Vault Module
# =============================================================================
# Creates a key vault whose data plane is governed by Azure RBAC:
# - Resource group
# - Key vault with purge protection and a deny-by-default firewall
# - Role assignments for administrators, officers and users
# - Optional private endpoint and audit log
# =============================================================================

data "azurerm_client_config" "current" {}

locals {
  resource_group_name = "rg-${var.name}-${var.environment}"

  # Vault names allow 3-24 letters, digits and hyphens and are unique across Azure.
  key_vault_name = "kv-${var.name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.owner != "" ? { Owner = var.owner } : {},
    var.description != "" ? { Description = substr(var.description, 0, 256) } : {},
  )
  role_assignments = merge(
    { for id in var.administrator_principal_ids : "Key Vault Administrator/${id}" => { role = "Key Vault Administrator", principal_id = id } },
    { for id in var.secrets_officer_principal_ids : "Key Vault Secrets Officer/${id}" => { role = "Key Vault Secrets Officer", principal_id = id } },
    { for id in var.secrets_user_principal_ids : "Key Vault Secrets User/${id}" => { role = "Key Vault Secrets User", principal_id = id } },
    { for id in var.crypto_user_principal_ids : "Key Vault Crypto User/${id}" => { role = "Key Vault Crypto User", principal_id = id } },
    { for id in var.certificates_officer_principal_ids : "Key Vault Certificates Officer/${id}" => { role = "Key Vault Certificates Officer", principal_id = id } },
  )
}

# =============================================================================
# Resource Group
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# =============================================================================
# Key Vault
# =============================================================================
resource "azurerm_key_vault" "main" {
  #checkov:skip=CKV2_AZURE_32:A private endpoint is opt-in through private_endpoint_subnet_id; without one the firewall denies everything not explicitly allowed
  name                = local.key_vault_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Access to secrets, keys and certificates is granted with Azure roles only;
  # access policies are not used.
  rbac_authorization_enabled = true

  # A deleted vault or object stays recoverable and cannot be purged early.
  purge_protection_enabled   = true
  soft_delete_retention_days = var.soft_delete_retention_days

  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment

  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action             = "Deny"
    bypass                     = var.trusted_services_bypass ? "AzureServices" : "None"
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = length(local.key_vault_name) <= 24
      error_message = "The vault name ${local.key_vault_name} must have at most 24 characters: shorten the name."
    }
  }
}

# =============================================================================
# Data Plane Access
# =============================================================================
resource "azurerm_role_assignment" "main" {
  for_each = local.role_assignments

  scope                = azurerm_key_vault.main.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}

# =============================================================================
# Private Endpoint
# =============================================================================
resource "azurerm_private_endpoint" "vault" {
  count = var.private_endpoint_subnet_id == null ? 0 : 1

  name                = "pe-${local.key_vault_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "vault"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id == null ? [] : [var.private_dns_zone_id]

    content {
      name                 = "default"
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }

  tags = local.common_tags
}

# =============================================================================
# Audit Log
# =============================================================================
resource "azurerm_monitor_diagnostic_setting" "vault" {
  count = var.log_analytics_workspace_id == null ? 0 : 1

  name                       = "diag-${local.key_vault_name}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
