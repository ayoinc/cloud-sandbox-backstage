# -----------------------------------------------------------------------------
# Object storage: storage account with a blob container, replicated to a
# second account in the secondary region when set
# -----------------------------------------------------------------------------

variable "storage_allowed_ips" {
  description = "Public IP addresses or CIDR ranges allowed to reach the storage account. Azure services are always allowed; everything else is denied."
  type        = list(string)
  default     = []
}

variable "secondary_region" {
  description = "Azure location that receives a replica of the storage account. Null disables replication."
  type        = string
  default     = null
}

locals {
  storage_replication_enabled = var.secondary_region != null
}

resource "azurerm_storage_account" "this" {
  name                = module.naming.global_compact["st"]
  resource_group_name = local.resource_group_name
  location            = var.region

  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.storage_allowed_ips
  }

  tags = module.tagging.tags
}

resource "azurerm_storage_container" "this" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Disaster-recovery copy in the secondary region.
resource "azurerm_storage_account" "replica" {
  count = local.storage_replication_enabled ? 1 : 0

  name                = module.naming.global_compact["stdr"]
  resource_group_name = local.resource_group_name
  location            = var.secondary_region

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.storage_allowed_ips
  }

  tags = module.tagging.tags
}

resource "azurerm_storage_container" "replica" {
  count = local.storage_replication_enabled ? 1 : 0

  name                  = "data"
  storage_account_id    = azurerm_storage_account.replica[0].id
  container_access_type = "private"
}

resource "azurerm_storage_object_replication" "this" {
  count = local.storage_replication_enabled ? 1 : 0

  source_storage_account_id      = azurerm_storage_account.this.id
  destination_storage_account_id = azurerm_storage_account.replica[0].id

  rules {
    source_container_name      = azurerm_storage_container.this.name
    destination_container_name = azurerm_storage_container.replica[0].name
  }
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "storage_container_name" {
  description = "Name of the blob container."
  value       = azurerm_storage_container.this.name
}

output "storage_replica_account_name" {
  description = "Name of the replica storage account in the secondary region. Null without a secondary region."
  value       = one(azurerm_storage_account.replica[*].name)
}
