# Azure Backup protects the blobs of the storage account and takes weekly
# long-term backups of a PostgreSQL server. MySQL, Cosmos DB and Redis are
# not supported by the vault: they rely on their own backups, which
# enable_backup extends (see database.tf).

locals {
  backup_storage_enabled    = var.enable_backup && var.enable_storage
  backup_postgresql_enabled = var.enable_backup && local.postgresql_enabled

  backup_redundancy = (
    var.enable_disaster_recovery ? "GeoRedundant" :
    local.production && local.zonal ? "ZoneRedundant" : "LocallyRedundant"
  )
}

resource "azurerm_data_protection_backup_vault" "this" {
  count = var.enable_backup ? 1 : 0

  name                = "${var.name_prefix}-backup"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  datastore_type      = "VaultStore"
  redundancy          = local.backup_redundancy

  # Geo-redundant backups can be restored in the paired region.
  cross_region_restore_enabled = var.enable_disaster_recovery ? true : null

  # Deleted backups stay recoverable for two weeks.
  soft_delete                = "On"
  retention_duration_in_days = 14

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Blobs
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "backup_storage" {
  count = local.backup_storage_enabled ? 1 : 0

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "Storage Account Backup Contributor"
  principal_id         = azurerm_data_protection_backup_vault.this[0].identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Operational backup: blobs can be restored to any point in time of the
# retention period.
resource "azurerm_data_protection_backup_policy_blob_storage" "this" {
  count = local.backup_storage_enabled ? 1 : 0

  name                                   = "${var.name_prefix}-blobs"
  vault_id                               = azurerm_data_protection_backup_vault.this[0].id
  operational_default_retention_duration = "P${local.blob_restore_days}D"
}

resource "azurerm_data_protection_backup_instance_blob_storage" "this" {
  count = local.backup_storage_enabled ? 1 : 0

  name               = "${var.name_prefix}-blobs"
  location           = azurerm_resource_group.this.location
  vault_id           = azurerm_data_protection_backup_vault.this[0].id
  storage_account_id = azurerm_storage_account.this[0].id
  backup_policy_id   = azurerm_data_protection_backup_policy_blob_storage.this[0].id

  depends_on = [time_sleep.backup_access]
}

# -----------------------------------------------------------------------------
# PostgreSQL
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "backup_postgresql" {
  count = local.backup_postgresql_enabled ? 1 : 0

  scope                = azurerm_postgresql_flexible_server.this[0].id
  role_definition_name = "PostgreSQL Flexible Server Long Term Retention Backup Role"
  principal_id         = azurerm_data_protection_backup_vault.this[0].identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "backup_resource_group" {
  count = local.backup_postgresql_enabled ? 1 : 0

  scope                = azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.this[0].identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# A full backup every Sunday at 02:00 UTC, kept for three months.
resource "azurerm_data_protection_backup_policy_postgresql_flexible_server" "this" {
  count = local.backup_postgresql_enabled ? 1 : 0

  name                            = "${var.name_prefix}-postgresql"
  vault_id                        = azurerm_data_protection_backup_vault.this[0].id
  backup_repeating_time_intervals = ["R/2025-01-05T02:00:00+00:00/P1W"]
  time_zone                       = "UTC"

  default_retention_rule {
    life_cycle {
      data_store_type = "VaultStore"
      duration        = "P3M"
    }
  }
}

resource "azurerm_data_protection_backup_instance_postgresql_flexible_server" "this" {
  count = local.backup_postgresql_enabled ? 1 : 0

  name             = "${var.name_prefix}-postgresql"
  location         = azurerm_resource_group.this.location
  vault_id         = azurerm_data_protection_backup_vault.this[0].id
  server_id        = azurerm_postgresql_flexible_server.this[0].id
  backup_policy_id = azurerm_data_protection_backup_policy_postgresql_flexible_server.this[0].id

  depends_on = [
    time_sleep.backup_access,
    azurerm_postgresql_flexible_server_database.this,
  ]
}

# Role assignments take a minute or two to become effective. The backup
# instances check their permissions when they are created.
resource "time_sleep" "backup_access" {
  count = local.backup_storage_enabled || local.backup_postgresql_enabled ? 1 : 0

  create_duration = "120s"

  triggers = {
    role_assignments = join(",", concat(
      azurerm_role_assignment.backup_storage[*].id,
      azurerm_role_assignment.backup_postgresql[*].id,
      azurerm_role_assignment.backup_resource_group[*].id,
    ))
  }
}
