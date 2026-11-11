# -----------------------------------------------------------------------------
# Azure Security Module - Main Resources
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "random_id" "security" {
  byte_length = 4
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Key Vault names are global, 3-24 alphanumeric characters starting with a
  # letter: "kv", up to 14 characters of project and environment, 8 of suffix.
  key_vault_name = "kv${substr(replace("${var.project_name}${var.environment}", "-", ""), 0, 14)}${random_id.security.hex}"

  # Log Analytics workspace names are limited to 63 characters.
  log_analytics_name = "${trimsuffix(substr(local.name_prefix, 0, 49), "-")}-security-logs"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })

  key_is_rsa = startswith(var.encryption_key_type, "RSA")
  key_is_hsm = endswith(var.encryption_key_type, "-HSM")

  key_vault_reachable = (
    var.network_acls.default_action == "Allow" ||
    length(var.network_acls.ip_rules) + length(var.network_acls.virtual_network_subnet_ids) > 0
  )
}

# -----------------------------------------------------------------------------
# User Assigned Managed Identity
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "main" {
  name                = "${local.name_prefix}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace (for Security Logs)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "security" {
  name                = local.log_analytics_name
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
  name                = local.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  rbac_authorization_enabled      = var.enable_rbac_authorization
  purge_protection_enabled        = var.enable_purge_protection
  soft_delete_retention_days      = var.soft_delete_retention_days

  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Data-plane access with access policies (when RBAC authorization is off)
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "terraform" {
  count = var.enable_rbac_authorization ? 0 : 1

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "GetRotationPolicy",
    "List",
    "Purge",
    "Recover",
    "SetRotationPolicy",
    "Update",
  ]

  secret_permissions = [
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Set",
  ]

  certificate_permissions = [
    "Create",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Update",
  ]
}

resource "azurerm_key_vault_access_policy" "identity" {
  count = var.enable_rbac_authorization ? 0 : 1

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.main.principal_id

  key_permissions         = ["Get", "List", "UnwrapKey", "WrapKey"]
  secret_permissions      = ["Get", "List"]
  certificate_permissions = ["Get", "List"]
}

# -----------------------------------------------------------------------------
# Data-plane access with Azure RBAC (when RBAC authorization is on)
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "identity_key_vault_crypto_user" {
  count = var.enable_rbac_authorization ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "identity_key_vault_secrets_user" {
  count = var.enable_rbac_authorization ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  principal_type       = "ServicePrincipal"
}

# The identity running Terraform administers keys and secrets in this vault.
resource "azurerm_role_assignment" "terraform_key_vault_admin" {
  count = var.enable_rbac_authorization ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Role assignments take up to a few minutes to reach the Key Vault data plane.
resource "time_sleep" "rbac_propagation" {
  count = var.enable_rbac_authorization && var.create_encryption_key ? 1 : 0

  create_duration = var.rbac_propagation_wait

  triggers = {
    role_assignment_id = azurerm_role_assignment.terraform_key_vault_admin[0].id
  }
}

# -----------------------------------------------------------------------------
# Key Vault Encryption Key (Optional)
# -----------------------------------------------------------------------------

# Keys are created through the vault's data plane, which the vault firewall
# guards: the machine running Terraform must be admitted by network_acls.
resource "azurerm_key_vault_key" "encryption" {
  count = var.create_encryption_key ? 1 : 0

  name         = "${local.name_prefix}-encryption-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = var.encryption_key_type
  key_size     = local.key_is_rsa ? var.encryption_key_size : null
  curve        = local.key_is_rsa ? null : var.encryption_key_curve

  key_opts = local.key_is_rsa ? ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"] : ["sign", "verify"]

  rotation_policy {
    automatic {
      time_before_expiry = var.key_rotation_time_before_expiry
    }

    expire_after         = var.key_expiration_period
    notify_before_expiry = var.key_notify_before_expiry
  }

  tags = local.common_tags

  depends_on = [
    azurerm_key_vault_access_policy.terraform,
    time_sleep.rbac_propagation,
  ]

  lifecycle {
    precondition {
      condition     = local.key_vault_reachable
      error_message = "create_encryption_key needs the machine running Terraform to reach the Key Vault: add its public IP to network_acls.ip_rules or its subnet to network_acls.virtual_network_subnet_ids."
    }
    precondition {
      condition     = !local.key_is_hsm || var.key_vault_sku == "premium"
      error_message = "HSM-backed key types (RSA-HSM, EC-HSM) require key_vault_sku = \"premium\"."
    }
  }
}

# -----------------------------------------------------------------------------
# Key Vault Diagnostic Settings
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "${local.name_prefix}-kv-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.security.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# -----------------------------------------------------------------------------
# Microsoft Defender for Cloud (Optional, subscription-wide)
# -----------------------------------------------------------------------------

resource "azurerm_security_center_subscription_pricing" "defender" {
  for_each = var.enable_defender ? toset(var.defender_resource_types) : toset([])

  tier          = "Standard"
  resource_type = each.value
}

# -----------------------------------------------------------------------------
# Application Insights (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${local.name_prefix}-appinsights"
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = var.application_insights_type
  workspace_id        = azurerm_log_analytics_workspace.security.id

  retention_in_days            = var.application_insights_retention_days
  sampling_percentage          = var.application_insights_sampling_percentage
  ip_masking_enabled           = !var.application_insights_disable_ip_masking
  local_authentication_enabled = !var.application_insights_local_auth_disabled
  internet_ingestion_enabled   = var.application_insights_internet_ingestion
  internet_query_enabled       = var.application_insights_internet_query

  tags = local.common_tags
}
