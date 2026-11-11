# -----------------------------------------------------------------------------
# Data warehouse: Azure Synapse workspace with a dedicated SQL pool.
# -----------------------------------------------------------------------------

locals {
  warehouse_sku = { small = "DW100c", medium = "DW500c", large = "DW1000c" }[var.warehouse_size]

  warehouse_key_name = "data-encryption"

  warehouse_entra_admin = var.warehouse_entra_admin != null ? var.warehouse_entra_admin : {
    login     = "terraform-pipeline"
    object_id = data.azurerm_client_config.current.object_id
  }
}

resource "random_password" "sql_admin" {
  count = local.create_synapse ? 1 : 0

  length           = 32
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#%*-_=+"
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  count = local.create_synapse ? 1 : 0

  name         = "synapse-sql-admin-password"
  value        = random_password.sql_admin[0].result
  content_type = "password of the SQL administrator ${var.warehouse_sql_admin_login}"
  key_vault_id = azurerm_key_vault.this[0].id

  depends_on = [azurerm_key_vault_access_policy.deployer]

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_synapse_workspace" "this" {
  count = local.create_synapse ? 1 : 0

  name                                 = "syn-${local.name_prefix}-${local.unique_suffix}"
  resource_group_name                  = module.resource_group.name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.this["synapse"].id

  sql_administrator_login          = var.warehouse_sql_admin_login
  sql_administrator_login_password = random_password.sql_admin[0].result
  # With access control SQL logins are refused and only Microsoft Entra identities can sign in.
  azuread_authentication_only = var.enable_access_control

  # Pipelines and data flows of the workspace report lineage to the catalog.
  purview_id = local.lineage_enabled ? azurerm_purview_account.this[0].id : null

  identity {
    type = "SystemAssigned"
  }

  dynamic "customer_managed_key" {
    for_each = local.customer_managed_keys ? [1] : []

    content {
      key_versionless_id = azurerm_key_vault_key.data[0].versionless_id
      key_name           = local.warehouse_key_name
    }
  }

  tags = local.common_tags
}

# A workspace created with a customer-managed key stays inactive until its identity can read the key and the key
# is activated. The SQL pool, the administrator and the firewall rules wait for that.
resource "azurerm_key_vault_access_policy" "synapse" {
  count = local.create_synapse && local.customer_managed_keys ? 1 : 0

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = azurerm_synapse_workspace.this[0].identity[0].tenant_id
  object_id    = azurerm_synapse_workspace.this[0].identity[0].principal_id

  key_permissions = ["Get", "WrapKey", "UnwrapKey"]
}

resource "azurerm_synapse_workspace_key" "this" {
  count = local.create_synapse && local.customer_managed_keys ? 1 : 0

  synapse_workspace_id                = azurerm_synapse_workspace.this[0].id
  customer_managed_key_name           = local.warehouse_key_name
  customer_managed_key_versionless_id = azurerm_key_vault_key.data[0].versionless_id
  active                              = true

  depends_on = [azurerm_key_vault_access_policy.synapse]
}

resource "azurerm_synapse_workspace_aad_admin" "this" {
  count = local.create_synapse ? 1 : 0

  synapse_workspace_id = azurerm_synapse_workspace.this[0].id
  login                = local.warehouse_entra_admin.login
  object_id            = local.warehouse_entra_admin.object_id
  tenant_id            = data.azurerm_client_config.current.tenant_id

  depends_on = [azurerm_synapse_workspace_key.this]
}

resource "azurerm_synapse_sql_pool" "warehouse" {
  count = local.create_synapse ? 1 : 0

  name                 = "warehouse"
  synapse_workspace_id = azurerm_synapse_workspace.this[0].id
  sku_name             = local.warehouse_sku
  create_mode          = "Default"

  # Transparent data encryption, with the workspace key when there is one and a Microsoft-managed key otherwise.
  data_encrypted = true

  storage_account_type      = local.is_production ? "GRS" : "LRS"
  geo_backup_policy_enabled = local.is_production

  tags = local.common_tags

  depends_on = [azurerm_synapse_workspace_key.this]

  # Remove prevent_destroy to delete the warehouse and its data on purpose.
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_synapse_firewall_rule" "allowed" {
  for_each = local.create_synapse ? toset(var.allowed_ip_ranges) : toset([])

  name                 = "allow-${replace(each.key, "/[./]/", "-")}"
  synapse_workspace_id = azurerm_synapse_workspace.this[0].id
  start_ip_address     = cidrhost(each.key, 0)
  end_ip_address       = cidrhost(each.key, -1)

  depends_on = [azurerm_synapse_workspace_key.this]
}
