# =============================================================================
# Azure Static Web App - Root Outputs
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.static_web.resource_group_name
}

output "static_web_app_id" {
  description = "Static Web App ID"
  value       = module.static_web.static_web_app_id
}

output "static_web_app_name" {
  description = "Static Web App name"
  value       = module.static_web.static_web_app_name
}

output "default_hostname" {
  description = "Default hostname"
  value       = module.static_web.default_hostname
}

output "url" {
  description = "Full URL of the Static Web App"
  value       = module.static_web.url
}

output "api_key" {
  description = "API key for deployment"
  value       = module.static_web.api_key
  sensitive   = true
}

output "build_config" {
  description = "Build configuration for the selected framework"
  value       = module.static_web.build_config
}

output "static_web_app_info" {
  description = "Summary of Static Web App configuration"
  value       = module.static_web.static_web_app_info
}
