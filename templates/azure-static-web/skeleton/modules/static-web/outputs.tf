# =============================================================================
# Azure Static Web App Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# -----------------------------------------------------------------------------
# Static Web App Outputs
# -----------------------------------------------------------------------------

output "static_web_app_id" {
  description = "Static Web App ID"
  value       = azurerm_static_web_app.main.id
}

output "static_web_app_name" {
  description = "Static Web App name"
  value       = azurerm_static_web_app.main.name
}

output "default_hostname" {
  description = "Default hostname of the Static Web App"
  value       = azurerm_static_web_app.main.default_host_name
}

output "url" {
  description = "Full URL of the Static Web App"
  value       = "https://${azurerm_static_web_app.main.default_host_name}"
}

output "api_key" {
  description = "API key for deployment (use in GitHub Actions)"
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Custom Domain Outputs
# -----------------------------------------------------------------------------

output "custom_domain_id" {
  description = "Custom domain ID (null if not configured)"
  value       = var.custom_domain != "" && var.sku_tier == "Standard" ? azurerm_static_web_app_custom_domain.main[0].id : null
}

output "custom_domain_validation_token" {
  description = "Custom domain validation token"
  value       = var.custom_domain != "" && var.sku_tier == "Standard" ? azurerm_static_web_app_custom_domain.main[0].validation_token : null
}

# -----------------------------------------------------------------------------
# Build Configuration Outputs
# -----------------------------------------------------------------------------

output "build_config" {
  description = "Build configuration for the selected framework"
  value       = local.selected_build_config
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "static_web_app_info" {
  description = "Summary of Static Web App configuration"
  value = {
    name             = azurerm_static_web_app.main.name
    id               = azurerm_static_web_app.main.id
    resource_group   = azurerm_resource_group.main.name
    location         = azurerm_resource_group.main.location
    sku_tier         = var.sku_tier
    framework        = var.framework
    default_hostname = azurerm_static_web_app.main.default_host_name
    url              = "https://${azurerm_static_web_app.main.default_host_name}"
    custom_domain    = var.custom_domain != "" ? var.custom_domain : null

    build_config = local.selected_build_config
  }
}
