output "sentinel_onboarding_id" {
  description = "The ID of the Sentinel Log Analytics Workspace onboarding"
  value       = azurerm_sentinel_log_analytics_workspace_onboarding.this.id
}

output "data_connector_ids" {
  description = "Map of data connector IDs by type"
  value = {
    aad                 = var.enable_aad_connector ? azurerm_sentinel_data_connector_azure_active_directory.this[0].id : null
    asc                 = var.enable_asc_connector ? azurerm_sentinel_data_connector_azure_security_center.this[0].id : null
    mcas                = var.enable_mcas_connector ? azurerm_sentinel_data_connector_microsoft_cloud_app_security.this[0].id : null
    office365           = var.enable_office365_connector ? azurerm_sentinel_data_connector_office_365.this[0].id : null
    threat_intelligence = var.enable_threat_intelligence_connector ? azurerm_sentinel_data_connector_threat_intelligence.this[0].id : null
  }
}

output "alert_rule_ids" {
  description = "Map of alert rule IDs by name"
  value       = { for k, v in azurerm_sentinel_alert_rule_scheduled.this : k => v.id }
}

output "automation_rule_ids" {
  description = "Map of automation rule IDs by name"
  value       = { for k, v in azurerm_sentinel_automation_rule.this : k => v.id }
}
