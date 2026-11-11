output "resource_group_name" {
  description = "Resource group that holds every resource of this repository."
  value       = module.resource_group.name
}

output "api_management_name" {
  description = "Name of the API Management instance."
  value       = azurerm_api_management.this.name
}

output "api_management_id" {
  description = "Resource ID of the API Management instance."
  value       = azurerm_api_management.this.id
}

output "gateway_url" {
  description = "Base URL of the gateway."
  value       = azurerm_api_management.this.gateway_url
}

output "developer_portal_url" {
  description = "URL of the developer portal, or null when the portal is switched off."
  value       = var.enable_portal ? azurerm_api_management.this.developer_portal_url : null
}

output "identity_principal_id" {
  description = "Object ID of the system-assigned identity of the instance, for role assignments on backends and key vaults."
  value       = azurerm_api_management.this.identity[0].principal_id
}

output "product_id" {
  description = "Product that holds the APIs. Callers subscribe to it to obtain a key."
  value       = azurerm_api_management_product.this.product_id
}

output "api_urls" {
  description = "Gateway URL of each API, keyed by API identifier."
  value       = { for key, api in azurerm_api_management_api.this : key => "${azurerm_api_management.this.gateway_url}/${api.path}" }
}

output "portal_application_client_id" {
  description = "Client ID of the app registration used for Microsoft Entra ID sign-in on the developer portal, or null when it is not created."
  value       = one(azuread_application.portal[*].client_id)
}

output "jwt_audiences" {
  description = "Audiences accepted by the token check, or null when tokens are not validated."
  value       = var.enable_jwt ? local.jwt_audiences : null
}

output "application_insights_name" {
  description = "Name of the Application Insights resource, or null when it is not created."
  value       = one(module.application_insights[*].app_insights_name)
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace, or null when it is not created."
  value       = one(module.log_analytics[*].workspace_id)
}
