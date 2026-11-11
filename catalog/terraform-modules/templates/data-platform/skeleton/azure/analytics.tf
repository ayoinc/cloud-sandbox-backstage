# -----------------------------------------------------------------------------
# BI: Power BI connects to the dedicated SQL endpoint of the warehouse. The
# Power BI service reaches it through the firewall rule for Azure services; a
# dedicated Power BI Embedded capacity is created once its administrators are
# named.
# -----------------------------------------------------------------------------

# Azure reads a rule from 0.0.0.0 to 0.0.0.0 with this name as "allow Azure services", which includes Power BI.
resource "azurerm_synapse_firewall_rule" "azure_services" {
  count = local.create_synapse && var.enable_bi_tools ? 1 : 0

  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.this[0].id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"

  depends_on = [azurerm_synapse_workspace_key.this]
}

resource "azurerm_powerbi_embedded" "this" {
  count = var.enable_bi_tools && length(var.power_bi_capacity_administrators) > 0 ? 1 : 0

  name                = "pbi${local.compact_prefix}${local.unique_suffix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  sku_name            = var.power_bi_capacity_sku
  administrators      = var.power_bi_capacity_administrators

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ML platform: Azure Machine Learning workspace with the storage account,
# Application Insights and Key Vault it requires.
# -----------------------------------------------------------------------------

module "log_analytics" {
  count  = var.enable_ml_platform ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/log-analytics?ref=${{ values.moduleRef }}"

  project             = local.project_slug
  environment         = local.module_environment
  resource_group_name = module.resource_group.name
  location            = var.location
  retention_in_days   = local.is_production ? 90 : 30
  tags                = local.common_tags
}

module "app_insights" {
  count  = var.enable_ml_platform ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/app-insights?ref=${{ values.moduleRef }}"

  name                = "appi-${local.name_prefix}-ml"
  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location
  application_type    = "web"
  workspace_id        = module.log_analytics[0].workspace_id
  tags                = local.common_tags
}

# Azure Machine Learning needs a storage account without a hierarchical namespace, so it cannot share the data
# lake, and its built-in datastores sign in with the account key.
#trivy:ignore:AVD-AZU-0012 Terraform runs on GitHub-hosted runners without a fixed address; set allowed_ip_ranges to deny other networks.
resource "azurerm_storage_account" "ml" {
  count = var.enable_ml_platform ? 1 : 0

  name                = "ml${local.compact_prefix}${local.unique_suffix}"
  resource_group_name = module.resource_group.name
  location            = var.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = local.is_production ? "GRS" : "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = local.restrict_networks ? "Deny" : "Allow"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ip_ranges
  }

  tags = local.common_tags

  # The key is set by azurerm_storage_account_customer_managed_key.ml once the account's identity can read it.
  # Remove prevent_destroy to delete the workspace's data on purpose.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [customer_managed_key]
  }
}

resource "azurerm_key_vault_access_policy" "ml_storage" {
  count = var.enable_ml_platform && local.customer_managed_keys ? 1 : 0

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = azurerm_storage_account.ml[0].identity[0].tenant_id
  object_id    = azurerm_storage_account.ml[0].identity[0].principal_id

  key_permissions = ["Get", "WrapKey", "UnwrapKey"]
}

resource "azurerm_storage_account_customer_managed_key" "ml" {
  count = var.enable_ml_platform && local.customer_managed_keys ? 1 : 0

  storage_account_id = azurerm_storage_account.ml[0].id
  key_vault_id       = azurerm_key_vault.this[0].id
  key_name           = azurerm_key_vault_key.data[0].name

  depends_on = [azurerm_key_vault_access_policy.ml_storage]
}

resource "azurerm_machine_learning_workspace" "this" {
  count = var.enable_ml_platform ? 1 : 0

  name                    = "mlw-${local.name_prefix}"
  resource_group_name     = module.resource_group.name
  location                = var.location
  application_insights_id = module.app_insights[0].app_insights_id
  key_vault_id            = azurerm_key_vault.this[0].id
  storage_account_id      = azurerm_storage_account.ml[0].id

  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  # The workspace configures the storage account when it is created; the account's key is set before that, so the
  # two changes to the account do not overlap.
  depends_on = [azurerm_storage_account_customer_managed_key.ml]
}
