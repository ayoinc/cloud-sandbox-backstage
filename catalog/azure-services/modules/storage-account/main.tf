################################################################################
# Azure Storage Account Module
# Creates a storage account with blob containers, network rules, and encryption
################################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

################################################################################
# Local Variables
################################################################################

locals {
  storage_account_name = var.storage_account_name

  tags = merge(
    var.tags,
    {
      Module = "storage-account"
    }
  )
}

################################################################################
# Storage Account
################################################################################

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  # Security
  min_tls_version                 = var.min_tls_version
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = var.allow_public_access
  shared_access_key_enabled       = var.shared_access_key_enabled

  # Blob properties
  dynamic "blob_properties" {
    for_each = var.blob_properties != null ? [var.blob_properties] : []
    content {
      versioning_enabled       = lookup(blob_properties.value, "versioning_enabled", true)
      change_feed_enabled      = lookup(blob_properties.value, "change_feed_enabled", false)
      last_access_time_enabled = lookup(blob_properties.value, "last_access_time_enabled", false)

      dynamic "delete_retention_policy" {
        for_each = lookup(blob_properties.value, "delete_retention_days", null) != null ? [1] : []
        content {
          days = blob_properties.value.delete_retention_days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = lookup(blob_properties.value, "container_delete_retention_days", null) != null ? [1] : []
        content {
          days = blob_properties.value.container_delete_retention_days
        }
      }

      dynamic "cors_rule" {
        for_each = lookup(blob_properties.value, "cors_rules", [])
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
    }
  }

  # Network rules
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      ip_rules                   = lookup(network_rules.value, "ip_rules", [])
      virtual_network_subnet_ids = lookup(network_rules.value, "subnet_ids", [])
      bypass                     = lookup(network_rules.value, "bypass", ["AzureServices"])

      dynamic "private_link_access" {
        for_each = lookup(network_rules.value, "private_link_access", [])
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = lookup(private_link_access.value, "endpoint_tenant_id", null)
        }
      }
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  # Customer managed key
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  tags = local.tags
}

################################################################################
# Blob Containers
################################################################################

resource "azurerm_storage_container" "containers" {
  for_each = { for c in var.containers : c.name => c }

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = lookup(each.value, "access_type", "private")
}

################################################################################
# Lifecycle Management Policy
################################################################################

resource "azurerm_storage_management_policy" "this" {
  count              = length(var.lifecycle_rules) > 0 ? 1 : 0
  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = lookup(rule.value, "enabled", true)

      filters {
        prefix_match = lookup(rule.value, "prefix_match", [])
        blob_types   = lookup(rule.value, "blob_types", ["blockBlob"])
      }

      actions {
        dynamic "base_blob" {
          for_each = lookup(rule.value, "base_blob", null) != null ? [rule.value.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = lookup(base_blob.value, "tier_to_cool_after_days", null)
            tier_to_archive_after_days_since_modification_greater_than = lookup(base_blob.value, "tier_to_archive_after_days", null)
            delete_after_days_since_modification_greater_than          = lookup(base_blob.value, "delete_after_days", null)
          }
        }

        dynamic "snapshot" {
          for_each = lookup(rule.value, "snapshot", null) != null ? [rule.value.snapshot] : []
          content {
            delete_after_days_since_creation_greater_than = snapshot.value.delete_after_days
          }
        }

        dynamic "version" {
          for_each = lookup(rule.value, "version", null) != null ? [rule.value.version] : []
          content {
            delete_after_days_since_creation = version.value.delete_after_days
          }
        }
      }
    }
  }
}

################################################################################
# Private Endpoint
################################################################################

resource "azurerm_private_endpoint" "blob" {
  count               = var.private_endpoint_config != null ? 1 : 0
  name                = "${local.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_config.subnet_id

  private_service_connection {
    name                           = "${local.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = lookup(var.private_endpoint_config, "private_dns_zone_ids", null) != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_endpoint_config.private_dns_zone_ids
    }
  }

  tags = local.tags
}

################################################################################
# Diagnostic Settings
################################################################################

resource "azurerm_monitor_diagnostic_setting" "this" {
  count                          = var.diagnostic_settings != null ? 1 : 0
  name                           = "${local.storage_account_name}-diag"
  target_resource_id             = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id     = lookup(var.diagnostic_settings, "log_analytics_workspace_id", null)
  storage_account_id             = lookup(var.diagnostic_settings, "storage_account_id", null)
  eventhub_authorization_rule_id = lookup(var.diagnostic_settings, "eventhub_authorization_rule_id", null)
  eventhub_name                  = lookup(var.diagnostic_settings, "eventhub_name", null)

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }

  metric {
    category = "Capacity"
    enabled  = true
  }
}
