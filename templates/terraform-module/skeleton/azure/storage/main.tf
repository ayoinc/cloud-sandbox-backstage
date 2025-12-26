# -----------------------------------------------------------------------------
# Azure Storage Module - Main Resources
# -----------------------------------------------------------------------------

# Random ID for unique naming
resource "random_id" "storage" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Storage Account
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = lower(replace("${var.project}${var.environment}${random_id.storage.hex}", "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  # Security settings
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  # Blob properties
  blob_properties {
    versioning_enabled = var.enable_versioning

    delete_retention_policy {
      days = var.delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  # Network rules (optional)
  dynamic "network_rules" {
    for_each = var.network_default_action != null ? [1] : []
    content {
      default_action             = var.network_default_action
      virtual_network_subnet_ids = var.allowed_subnet_ids
      ip_rules                   = var.allowed_ip_ranges
      bypass                     = ["AzureServices"]
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-storage"
    Environment = var.environment
    Project     = var.project
  })
}

# -----------------------------------------------------------------------------
# Storage Containers
# -----------------------------------------------------------------------------

resource "azurerm_storage_container" "main" {
  for_each = toset(var.container_names)

  name                  = each.value
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Lifecycle Management Policy
# -----------------------------------------------------------------------------

resource "azurerm_storage_management_policy" "main" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        prefix_match = rule.value.prefix_match
        blob_types   = rule.value.blob_types
      }

      actions {
        # Base blob actions
        dynamic "base_blob" {
          for_each = rule.value.base_blob_tier_to_cool_after_days != null || rule.value.base_blob_tier_to_archive_after_days != null || rule.value.base_blob_delete_after_days != null ? [1] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = rule.value.base_blob_tier_to_cool_after_days
            tier_to_archive_after_days_since_modification_greater_than = rule.value.base_blob_tier_to_archive_after_days
            delete_after_days_since_modification_greater_than          = rule.value.base_blob_delete_after_days
          }
        }

        # Snapshot actions
        dynamic "snapshot" {
          for_each = rule.value.snapshot_delete_after_days != null ? [1] : []
          content {
            delete_after_days_since_creation_greater_than = rule.value.snapshot_delete_after_days
          }
        }

        # Version actions
        dynamic "version" {
          for_each = rule.value.version_delete_after_days != null ? [1] : []
          content {
            delete_after_days_since_creation = rule.value.version_delete_after_days
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Azure File Share (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_storage_share" "main" {
  count = var.enable_file_share ? 1 : 0

  name                 = "${var.project}-${var.environment}-share"
  storage_account_name = azurerm_storage_account.main.name
  quota                = var.file_share_quota_gb
  access_tier          = var.file_share_access_tier

  # Optional ACL settings can be added here if needed
}

# -----------------------------------------------------------------------------
# Diagnostic Settings (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "storage" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.project}-${var.environment}-storage-diag"
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

  metric {
    category = "Transaction"
    enabled  = true
  }
}
