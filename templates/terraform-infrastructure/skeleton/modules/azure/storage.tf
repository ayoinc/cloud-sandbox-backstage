locals {
  # Geo-redundant when disaster recovery is on, zone-redundant in production.
  storage_replication_type = (
    var.enable_disaster_recovery ? (local.zonal ? "GZRS" : "GRS") :
    local.production && local.zonal ? "ZRS" : "LRS"
  )

  # Azure Backup restores blobs to a point in time of the last 30 days, which
  # needs soft-deleted blobs to be kept a little longer.
  blob_restore_days      = 30
  blob_soft_delete_days  = var.enable_backup ? 35 : 7
  content_container_name = "content"
  cdn_container_name     = "cdn"
  data_lake_containers   = ["raw", "curated"]
}

# -----------------------------------------------------------------------------
# Object storage
# -----------------------------------------------------------------------------

# The firewall of the account denies every public address. Clients inside
# the network use the private endpoint and sign in with Microsoft Entra ID:
# account keys are switched off.
resource "azurerm_storage_account" "this" {
  count = var.enable_storage ? 1 : 0

  name                     = "${substr(local.compact_prefix, 0, 14)}st${local.suffix}"
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = local.storage_replication_type

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  infrastructure_encryption_enabled = true

  # Only the container that Front Door serves is readable without signing in.
  allow_nested_items_to_be_public = var.enable_cdn

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = var.enable_backup

    delete_retention_policy {
      days = local.blob_soft_delete_days
    }

    container_delete_retention_policy {
      days = local.blob_soft_delete_days
    }

    dynamic "restore_policy" {
      for_each = var.enable_backup ? [1] : []

      content {
        days = local.blob_restore_days
      }
    }
  }

  dynamic "identity" {
    for_each = var.enable_kms ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.encryption[0].id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.enable_kms ? [1] : []

    content {
      key_vault_key_id          = local.kms_key_id
      user_assigned_identity_id = azurerm_user_assigned_identity.encryption[0].id
    }
  }

  tags = local.tags

  depends_on = [time_sleep.encryption_access]
}

resource "azurerm_storage_container" "content" {
  count = var.enable_storage ? 1 : 0

  name                  = local.content_container_name
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = "private"
}

# Blobs move to cheaper access tiers as they age; old versions are removed.
resource "azurerm_storage_management_policy" "this" {
  count = var.enable_storage && var.enable_cost_optimization ? 1 : 0

  storage_account_id = azurerm_storage_account.this[0].id

  rule {
    name    = "tier-content"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["${local.content_container_name}/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        tier_to_cold_after_days_since_modification_greater_than = 90
      }

      version {
        change_tier_to_cool_after_days_since_creation = 30
        delete_after_days_since_creation              = 365
      }
    }
  }

  depends_on = [azurerm_storage_container.content]
}

# -----------------------------------------------------------------------------
# Data lake
# -----------------------------------------------------------------------------

# A hierarchical namespace turns the containers into Data Lake Storage Gen2
# file systems. It excludes blob versioning, so soft delete protects the data.
resource "azurerm_storage_account" "data_lake" {
  count = local.data_lake_enabled ? 1 : 0

  name                     = "${substr(local.compact_prefix, 0, 14)}dl${local.suffix}"
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = local.storage_replication_type
  is_hns_enabled           = true

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false

  infrastructure_encryption_enabled = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  dynamic "identity" {
    for_each = var.enable_kms ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.encryption[0].id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.enable_kms ? [1] : []

    content {
      key_vault_key_id          = local.kms_key_id
      user_assigned_identity_id = azurerm_user_assigned_identity.encryption[0].id
    }
  }

  tags = local.tags

  depends_on = [time_sleep.encryption_access]
}

resource "azurerm_storage_container" "data_lake" {
  for_each = local.data_lake_enabled ? toset(local.data_lake_containers) : toset([])

  name                  = each.key
  storage_account_id    = azurerm_storage_account.data_lake[0].id
  container_access_type = "private"
}

# Raw data is read rarely once it has been processed, curated data stays in
# use for longer.
resource "azurerm_storage_management_policy" "data_lake" {
  count = local.data_lake_enabled ? 1 : 0

  storage_account_id = azurerm_storage_account.data_lake[0].id

  rule {
    name    = "tier-raw"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["raw/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        tier_to_cold_after_days_since_modification_greater_than = 180
      }
    }
  }

  rule {
    name    = "tier-curated"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["curated/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 90
      }
    }
  }

  depends_on = [azurerm_storage_container.data_lake]
}
