# -----------------------------------------------------------------------------
# Azure Security Module - Main Resources
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# Random ID for unique naming
resource "random_id" "security" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Local Variables
# -----------------------------------------------------------------------------

locals {
  key_vault_name = lower(replace("kv-${var.project_name}-${var.environment}-${random_id.security.hex}", "-", ""))
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}

# -----------------------------------------------------------------------------
# User Assigned Managed Identity
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.project_name}-${var.environment}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace (for Security Logs)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "security" {
  name                = "${var.project_name}-${var.environment}-security-logs"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Azure Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                = substr(local.key_vault_name, 0, 24) # Key Vault names max 24 chars
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku

  # Security settings
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.enable_purge_protection
  soft_delete_retention_days      = var.soft_delete_retention_days

  # Network ACLs
  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  # Access policy for the current client (when not using RBAC)
  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : [1]
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id

      key_permissions = [
        "Create",
        "Delete",
        "Get",
        "List",
        "Purge",
        "Recover",
        "Update",
        "GetRotationPolicy",
        "SetRotationPolicy"
      ]

      secret_permissions = [
        "Delete",
        "Get",
        "List",
        "Purge",
        "Recover",
        "Set"
      ]

      certificate_permissions = [
        "Create",
        "Delete",
        "Get",
        "List",
        "Purge",
        "Recover",
        "Update"
      ]
    }
  }

  # Access policy for the managed identity (when not using RBAC)
  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : [1]
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = azurerm_user_assigned_identity.main.principal_id

      key_permissions = [
        "Get",
        "List",
        "UnwrapKey",
        "WrapKey"
      ]

      secret_permissions = [
        "Get",
        "List"
      ]

      certificate_permissions = [
        "Get",
        "List"
      ]
    }
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Key Vault Encryption Key
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_key" "encryption" {
  name         = "${var.project_name}-${var.environment}-encryption-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = var.encryption_key_type
  key_size     = var.encryption_key_size

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = var.key_rotation_time_before_expiry
    }

    expire_after         = var.key_expiration_period
    notify_before_expiry = var.key_notify_before_expiry
  }

  tags = local.common_tags

  depends_on = [azurerm_key_vault.main]
}

# -----------------------------------------------------------------------------
# Role Assignments for Managed Identity (when using RBAC)
# -----------------------------------------------------------------------------

# Key Vault Crypto User role for the managed identity
resource "azurerm_role_assignment" "identity_key_vault_crypto_user" {
  count = var.enable_rbac_authorization ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Key Vault Secrets User role for the managed identity
resource "azurerm_role_assignment" "identity_key_vault_secrets_user" {
  count = var.enable_rbac_authorization ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Key Vault Administrator role for the current client (Terraform)
resource "azurerm_role_assignment" "terraform_key_vault_admin" {
  count = var.enable_rbac_authorization ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# -----------------------------------------------------------------------------
# Key Vault Diagnostic Settings
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "${var.project_name}-${var.environment}-kv-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.security.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# -----------------------------------------------------------------------------
# Microsoft Defender for Cloud (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_security_center_subscription_pricing" "defender_key_vaults" {
  count = var.enable_defender ? 1 : 0

  tier          = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "defender_storage" {
  count = var.enable_defender ? 1 : 0

  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "defender_arm" {
  count = var.enable_defender ? 1 : 0

  tier          = "Standard"
  resource_type = "Arm"
}

# -----------------------------------------------------------------------------
# Application Insights (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-${var.environment}-appinsights"
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = var.application_insights_type
  workspace_id        = azurerm_log_analytics_workspace.security.id

  # Sampling and retention settings
  retention_in_days             = var.application_insights_retention_days
  sampling_percentage           = var.application_insights_sampling_percentage
  disable_ip_masking            = var.application_insights_disable_ip_masking
  local_authentication_disabled = var.application_insights_local_auth_disabled
  internet_ingestion_enabled    = var.application_insights_internet_ingestion
  internet_query_enabled        = var.application_insights_internet_query

  tags = local.common_tags
}
