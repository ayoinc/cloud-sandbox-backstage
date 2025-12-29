output "diagnostic_setting_id" {
  description = "The ID of the diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.this.id
}

output "diagnostic_setting_name" {
  description = "The name of the diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.this.name
}
