# =============================================================================
# Azure Storage Account Module
# =============================================================================
# Creates a storage account that is reachable only through Entra ID and the
# network paths you allow:
# - Resource group
# - Storage account (no shared keys, no anonymous access, TLS 1.2, double encryption)
# - Private blob containers
# - Lifecycle management policy
# - Optional private endpoint, customer-managed key, role assignments and logs
# =============================================================================

locals {
  resource_group_name = "rg-${var.name}-${var.environment}"

  # Storage account names allow 3-24 lowercase letters and digits.
  storage_account_name = replace("st${var.name}${var.environment}", "-", "")

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

  lifecycle_tiering = var.cool_after_days != null || var.archive_after_days != null || var.expire_after_days != null
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
# Customer-Managed Key Access
# =============================================================================
# The account reads its key with a dedicated identity, so the key can be
# granted before the account exists.
resource "azurerm_user_assigned_identity" "encryption" {
  count = var.customer_managed_key == null ? 0 : 1

  name                = "id-${var.name}-${var.environment}-encryption"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "encryption" {
  count = var.customer_managed_key == null ? 0 : 1

  scope                = var.customer_managed_key.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.encryption[0].principal_id
  principal_type       = "ServicePrincipal"
}

# =============================================================================
# Storage Account
# =============================================================================
resource "azurerm_storage_account" "main" {
  #checkov:skip=CKV2_AZURE_1:A customer-managed key is opt-in through customer_managed_key; data is always encrypted twice with platform-managed keys
  #checkov:skip=CKV2_AZURE_33:A private endpoint is opt-in through private_endpoint_subnet_id; without one the firewall denies everything not explicitly allowed
  #checkov:skip=CKV_AZURE_206:Redundancy is a per-environment choice (replication_type); production uses geo-zone-redundant storage
  #checkov:skip=CKV_AZURE_33:The queue service is not used; shared keys are disabled so nothing can write to it without an Entra ID role
  #checkov:skip=CKV2_AZURE_41:Shared keys are disabled, which leaves only user delegation SAS tokens that Azure limits to seven days
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  access_tier              = var.access_tier

  # Entra ID is the only way in: no account keys, no SAS signed with them, no
  # anonymous containers, no local SFTP users.
  shared_access_key_enabled        = false
  default_to_oauth_authentication  = true
  allow_nested_items_to_be_public  = false
  local_user_enabled               = false
  cross_tenant_replication_enabled = false

  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  infrastructure_encryption_enabled = true
  public_network_access             = var.public_network_access_enabled ? "Enabled" : "Disabled"

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  blob_properties {
    versioning_enabled  = var.versioning_enabled
    change_feed_enabled = var.versioning_enabled

    delete_retention_policy {
      days = var.soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  dynamic "identity" {
    for_each = azurerm_user_assigned_identity.encryption

    content {
      type         = "UserAssigned"
      identity_ids = [identity.value.id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = azurerm_user_assigned_identity.encryption

    content {
      key_vault_key_id          = var.customer_managed_key.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.id
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.encryption]

  lifecycle {
    precondition {
      condition     = length(local.storage_account_name) >= 3 && length(local.storage_account_name) <= 24
      error_message = "The storage account name ${local.storage_account_name} must have 3 to 24 characters: shorten the name."
    }
  }
}

# =============================================================================
# Containers
# =============================================================================
resource "azurerm_storage_container" "main" {
  for_each = var.container_names

  name                  = each.value
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# =============================================================================
# Lifecycle Management
# =============================================================================
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  dynamic "rule" {
    for_each = local.lifecycle_tiering ? [1] : []

    content {
      name    = "tier-and-expire"
      enabled = true

      filters {
        blob_types = ["blockBlob"]
      }

      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = var.cool_after_days
          tier_to_archive_after_days_since_modification_greater_than = var.archive_after_days
          delete_after_days_since_modification_greater_than          = var.expire_after_days
        }
      }
    }
  }

  rule {
    name    = "expire-previous-versions"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      version {
        delete_after_days_since_creation = var.noncurrent_version_retention_days
      }

      snapshot {
        delete_after_days_since_creation_greater_than = var.noncurrent_version_retention_days
      }
    }
  }
}

# =============================================================================
# Private Endpoint
# =============================================================================
resource "azurerm_private_endpoint" "blob" {
  count = var.private_endpoint_subnet_id == null ? 0 : 1

  name                = "pe-${local.storage_account_name}-blob"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
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
# Data Access
# =============================================================================
resource "azurerm_role_assignment" "blob_data_contributor" {
  for_each = var.blob_data_contributor_principal_ids

  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "blob_data_reader" {
  for_each = var.blob_data_reader_principal_ids

  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}

# =============================================================================
# Diagnostic Logs
# =============================================================================
resource "azurerm_monitor_diagnostic_setting" "blob" {
  count = var.log_analytics_workspace_id == null ? 0 : 1

  name                       = "diag-${local.storage_account_name}-blob"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}
