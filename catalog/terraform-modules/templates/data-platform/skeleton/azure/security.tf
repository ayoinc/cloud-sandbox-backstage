# -----------------------------------------------------------------------------
# Key Vault: holds the customer-managed encryption key, the SQL administrator
# password of the warehouse and the secrets of the Machine Learning workspace.
# -----------------------------------------------------------------------------

#trivy:ignore:AVD-AZU-0013 Terraform runs on GitHub-hosted runners without a fixed address and writes keys and secrets; set allowed_ip_ranges to deny other networks.
resource "azurerm_key_vault" "this" {
  count = local.create_key_vault ? 1 : 0

  name                = "kv${local.compact_prefix}${local.unique_suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Services refuse a customer-managed key from a vault that can be purged.
  purge_protection_enabled   = true
  soft_delete_retention_days = local.is_production ? 90 : 7

  network_acls {
    default_action = local.restrict_networks ? "Deny" : "Allow"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
  }

  tags = local.common_tags

  # Remove prevent_destroy to delete the vault, its key and its secrets on purpose.
  lifecycle {
    prevent_destroy = true
  }
}

# The identity Terraform runs with creates the key and the secrets.
resource "azurerm_key_vault_access_policy" "deployer" {
  count = local.create_key_vault ? 1 : 0

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions    = ["Get", "List", "Create", "Update", "Delete", "Recover", "Purge", "GetRotationPolicy", "SetRotationPolicy"]
  secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Purge"]
}

# One key encrypts the data lake, the Machine Learning storage account, the Synapse workspace and the Databricks
# root storage. Each of those services reads it with its own managed identity.
resource "azurerm_key_vault_key" "data" {
  count = local.customer_managed_keys ? 1 : 0

  name         = "data-encryption"
  key_vault_id = azurerm_key_vault.this[0].id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["unwrapKey", "wrapKey"]

  depends_on = [azurerm_key_vault_access_policy.deployer]

  # Data encrypted with this key is lost with it.
  lifecycle {
    prevent_destroy = true
  }
}
