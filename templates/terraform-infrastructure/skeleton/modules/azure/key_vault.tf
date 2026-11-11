locals {
  # One vault holds the secrets and the customer-managed key.
  key_vault_enabled = var.enable_kms || var.enable_secrets_manager

  kms_key_name = "${var.name_prefix}-cmk"

  # Versionless key URI: services follow the yearly rotation by themselves.
  kms_key_id = var.enable_kms ? jsondecode(azurerm_resource_group_template_deployment.encryption_key[0].output_content).keyUri.value : null

  # Geo-redundant backups of PostgreSQL and MySQL are encrypted with a key
  # that has to live in the region the backups are copied to.
  geo_encryption_enabled = (
    var.enable_kms && var.enable_disaster_recovery && var.enable_database &&
    contains(["postgresql", "mysql"], var.database_type)
  )
  geo_kms_key_id = local.geo_encryption_enabled ? jsondecode(azurerm_resource_group_template_deployment.geo_encryption_key[0].output_content).keyUri.value : null

  # The vault firewall admits trusted Azure services and private endpoints
  # only, so the machine that runs Terraform cannot use the vault data plane.
  # Keys and secrets are created through Azure Resource Manager instead.
  encryption_key_template = jsonencode({
    "$schema"      = local.arm_template_schema
    contentVersion = "1.0.0.0"
    parameters = {
      vaultName = { type = "string" }
      keyName   = { type = "string" }
    }
    resources = [{
      type       = "Microsoft.KeyVault/vaults/keys"
      apiVersion = "2023-07-01"
      name       = "[concat(parameters('vaultName'), '/', parameters('keyName'))]"
      properties = {
        kty     = "RSA"
        keySize = 3072
        keyOps  = ["wrapKey", "unwrapKey"]
        rotationPolicy = {
          lifetimeActions = [{
            trigger = { timeAfterCreate = "P1Y" }
            action  = { type = "rotate" }
          }]
        }
      }
    }]
    outputs = {
      keyUri = {
        type  = "string"
        value = "[reference(resourceId('Microsoft.KeyVault/vaults/keys', parameters('vaultName'), parameters('keyName'))).keyUri]"
      }
    }
  })

  secret_template = jsonencode({
    "$schema"      = local.arm_template_schema
    contentVersion = "1.0.0.0"
    parameters = {
      vaultName   = { type = "string" }
      secretName  = { type = "string" }
      secretValue = { type = "securestring" }
    }
    resources = [{
      type       = "Microsoft.KeyVault/vaults/secrets"
      apiVersion = "2023-07-01"
      name       = "[concat(parameters('vaultName'), '/', parameters('secretName'))]"
      properties = {
        contentType = "application/json"
        value       = "[parameters('secretValue')]"
      }
    }]
    outputs = {
      secretUri = {
        type  = "string"
        value = "[reference(resourceId('Microsoft.KeyVault/vaults/secrets', parameters('vaultName'), parameters('secretName'))).secretUri]"
      }
    }
  })
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

# Services that encrypt with the customer-managed key require purge
# protection on the vault, so the key enables it as well.
resource "azurerm_key_vault" "this" {
  count = local.key_vault_enabled ? 1 : 0

  name                = "kv-${substr(local.compact_prefix, 0, 12)}-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true
  purge_protection_enabled   = var.require_deletion_protection || var.enable_kms
  soft_delete_retention_days = 90

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Customer-managed key
# -----------------------------------------------------------------------------

resource "azurerm_resource_group_template_deployment" "encryption_key" {
  count = var.enable_kms ? 1 : 0

  name                = "${var.name_prefix}-encryption-key"
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode     = "Incremental"
  template_content    = local.encryption_key_template

  parameters_content = jsonencode({
    vaultName = { value = azurerm_key_vault.this[0].name }
    keyName   = { value = local.kms_key_name }
  })

  tags = local.tags
}

# Storage accounts and the database read the key with this identity.
resource "azurerm_user_assigned_identity" "encryption" {
  count = var.enable_kms ? 1 : 0

  name                = "${var.name_prefix}-encryption"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_role_assignment" "encryption" {
  count = var.enable_kms ? 1 : 0

  scope                = azurerm_key_vault.this[0].id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.encryption[0].principal_id
  principal_type       = "ServicePrincipal"
}

# -----------------------------------------------------------------------------
# Key for geo-redundant database backups
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "secondary" {
  count = local.geo_encryption_enabled ? 1 : 0

  name     = "${var.name_prefix}-dr-rg"
  location = var.secondary_region

  tags = local.tags
}

resource "azurerm_key_vault" "secondary" {
  count = local.geo_encryption_enabled ? 1 : 0

  name                = "kv-${substr(local.compact_prefix, 0, 9)}-dr-${local.suffix}"
  location            = azurerm_resource_group.secondary[0].location
  resource_group_name = azurerm_resource_group.secondary[0].name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.tags
}

resource "azurerm_resource_group_template_deployment" "geo_encryption_key" {
  count = local.geo_encryption_enabled ? 1 : 0

  name                = "${var.name_prefix}-geo-encryption-key"
  resource_group_name = azurerm_resource_group.secondary[0].name
  deployment_mode     = "Incremental"
  template_content    = local.encryption_key_template

  parameters_content = jsonencode({
    vaultName = { value = azurerm_key_vault.secondary[0].name }
    keyName   = { value = local.kms_key_name }
  })

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "geo_encryption" {
  count = local.geo_encryption_enabled ? 1 : 0

  name                = "${var.name_prefix}-geo-encryption"
  location            = azurerm_resource_group.secondary[0].location
  resource_group_name = azurerm_resource_group.secondary[0].name

  tags = local.tags
}

resource "azurerm_role_assignment" "geo_encryption" {
  count = local.geo_encryption_enabled ? 1 : 0

  scope                = azurerm_key_vault.secondary[0].id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.geo_encryption[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Role assignments take a minute or two to reach the vault. Everything that
# encrypts with the key waits for this before it is created.
resource "time_sleep" "encryption_access" {
  count = var.enable_kms ? 1 : 0

  create_duration = "120s"

  triggers = {
    role_assignments = join(",", concat(azurerm_role_assignment.encryption[*].id, azurerm_role_assignment.geo_encryption[*].id))
  }
}
