# -----------------------------------------------------------------------------
# Azure Security Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Key Vault Outputs
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_resource_group" {
  description = "The resource group containing the Key Vault"
  value       = azurerm_key_vault.main.resource_group_name
}

output "key_vault_tenant_id" {
  description = "The Azure AD tenant ID of the Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}

# -----------------------------------------------------------------------------
# Encryption Key Outputs
# -----------------------------------------------------------------------------

output "encryption_key_id" {
  description = "The ID of the encryption key"
  value       = azurerm_key_vault_key.encryption.id
}

output "encryption_key_version" {
  description = "The current version of the encryption key"
  value       = azurerm_key_vault_key.encryption.version
}

output "encryption_key_versionless_id" {
  description = "The versionless ID of the encryption key (for CMK configurations)"
  value       = azurerm_key_vault_key.encryption.versionless_id
}

output "encryption_key_name" {
  description = "The name of the encryption key"
  value       = azurerm_key_vault_key.encryption.name
}

output "encryption_key_public_key_pem" {
  description = "The public key in PEM format"
  value       = azurerm_key_vault_key.encryption.public_key_pem
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Managed Identity Outputs
# -----------------------------------------------------------------------------

output "managed_identity_id" {
  description = "The ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "managed_identity_principal_id" {
  description = "The Principal ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "managed_identity_client_id" {
  description = "The Client ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "managed_identity_name" {
  description = "The name of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.main.name
}

output "managed_identity_tenant_id" {
  description = "The Tenant ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.main.tenant_id
}

# -----------------------------------------------------------------------------
# Log Analytics Outputs
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.security.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.security.name
}

output "log_analytics_workspace_primary_key" {
  description = "The primary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.security.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_secondary_key" {
  description = "The secondary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.security.secondary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_customer_id" {
  description = "The Workspace (Customer) ID for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.security.workspace_id
}

# -----------------------------------------------------------------------------
# Application Insights Outputs (Conditional)
# -----------------------------------------------------------------------------

output "application_insights_id" {
  description = "The ID of the Application Insights instance"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_app_id" {
  description = "The App ID of the Application Insights instance"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].app_id : null
}

output "application_insights_instrumentation_key" {
  description = "The Instrumentation Key of the Application Insights instance"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The Connection String of the Application Insights instance"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Current Client Configuration Outputs
# -----------------------------------------------------------------------------

output "current_tenant_id" {
  description = "The Azure AD tenant ID of the current client"
  value       = data.azurerm_client_config.current.tenant_id
}

output "current_subscription_id" {
  description = "The Azure subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "current_subscription_display_name" {
  description = "The display name of the Azure subscription"
  value       = data.azurerm_subscription.current.display_name
}
