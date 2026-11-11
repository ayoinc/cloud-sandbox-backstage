# -----------------------------------------------------------------------------
# Azure Storage Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Storage account names are global, 3-24 characters, lowercase alphanumeric:
  # up to 16 characters of project and environment plus an 8 character suffix.
  storage_account_name = "${substr(replace("${var.project_name}${var.environment}", "-", ""), 0, 16)}${random_id.storage.hex}"

  archive_rules = [for rule in var.lifecycle_rules : rule.name if rule.base_blob_tier_to_archive_after_days != null]
  tiering_rules = [for rule in var.lifecycle_rules : rule.name if rule.base_blob_tier_to_archive_after_days != null || rule.base_blob_tier_to_cool_after_days != null]
}

resource "random_id" "storage" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Storage Account
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  infrastructure_encryption_enabled = var.enable_infrastructure_encryption
  public_network_access_enabled     = var.public_network_access_enabled

  blob_properties {
    versioning_enabled = var.enable_versioning

    delete_retention_policy {
      days = var.delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  network_rules {
    default_action             = var.network_default_action
    virtual_network_subnet_ids = var.allowed_subnet_ids
    ip_rules                   = var.allowed_ip_ranges
    bypass                     = ["AzureServices"]
  }

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-storage"
    Environment = var.environment
    Project     = var.project_name
  })

  lifecycle {
    precondition {
      condition     = var.account_tier == "Standard" ? var.account_kind == "StorageV2" : contains(["LRS", "ZRS"], var.replication_type)
      error_message = "Standard accounts must use account_kind StorageV2, and Premium accounts only support LRS or ZRS replication."
    }
    precondition {
      condition     = var.account_tier == "Standard" || var.account_kind != "StorageV2"
      error_message = "Premium accounts must use account_kind BlockBlobStorage (blobs) or FileStorage (file shares)."
    }
  }
}

# -----------------------------------------------------------------------------
# Storage Containers
# -----------------------------------------------------------------------------

# Containers are managed through the resource manager API (storage_account_id),
# so they can be created while the account firewall denies public traffic.
resource "azurerm_storage_container" "main" {
  for_each = toset(var.container_names)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"

  lifecycle {
    precondition {
      condition     = var.account_kind != "FileStorage"
      error_message = "FileStorage accounts cannot hold blob containers: set container_names to []."
    }
  }
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
        dynamic "base_blob" {
          for_each = rule.value.base_blob_tier_to_cool_after_days != null || rule.value.base_blob_tier_to_archive_after_days != null || rule.value.base_blob_delete_after_days != null ? [1] : []

          content {
            tier_to_cool_after_days_since_modification_greater_than    = rule.value.base_blob_tier_to_cool_after_days
            tier_to_archive_after_days_since_modification_greater_than = rule.value.base_blob_tier_to_archive_after_days
            delete_after_days_since_modification_greater_than          = rule.value.base_blob_delete_after_days
          }
        }

        dynamic "snapshot" {
          for_each = rule.value.snapshot_delete_after_days != null ? [1] : []

          content {
            delete_after_days_since_creation_greater_than = rule.value.snapshot_delete_after_days
          }
        }

        dynamic "version" {
          for_each = rule.value.version_delete_after_days != null ? [1] : []

          content {
            delete_after_days_since_creation = rule.value.version_delete_after_days
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.account_kind != "FileStorage"
      error_message = "FileStorage accounts do not support lifecycle management: set lifecycle_rules to []."
    }
    precondition {
      condition     = var.account_tier == "Standard" || length(local.tiering_rules) == 0
      error_message = "Premium accounts do not support access tiers. Remove the cool and archive settings from lifecycle rules: ${join(", ", local.tiering_rules)}."
    }
    precondition {
      condition     = !strcontains(var.replication_type, "ZRS") || length(local.archive_rules) == 0
      error_message = "The archive tier is not available with zone-redundant replication. Remove the archive setting from lifecycle rules: ${join(", ", local.archive_rules)}."
    }
  }
}

# -----------------------------------------------------------------------------
# Azure File Share (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_storage_share" "main" {
  count = var.enable_file_share ? 1 : 0

  name               = "${local.name_prefix}-share"
  storage_account_id = azurerm_storage_account.main.id
  quota              = var.file_share_quota_gb
  access_tier        = var.file_share_access_tier

  lifecycle {
    precondition {
      condition     = var.account_kind == "FileStorage" ? var.file_share_access_tier == "Premium" : var.account_kind == "StorageV2" && var.file_share_access_tier != "Premium"
      error_message = "File shares need account_kind StorageV2 with access tier Hot, Cool or TransactionOptimized, or account_kind FileStorage with access tier Premium."
    }
    precondition {
      condition     = var.account_kind != "FileStorage" || var.file_share_quota_gb >= 100
      error_message = "Premium file shares must be at least 100 GB."
    }
  }
}

# -----------------------------------------------------------------------------
# Diagnostic Settings (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "storage" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${local.name_prefix}-storage-diag"
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
