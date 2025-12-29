output "app_insights_id" {
  description = "The ID of the Application Insights resource"
  value       = azurerm_application_insights.this.id
}

output "app_insights_name" {
  description = "The name of the Application Insights resource"
  value       = azurerm_application_insights.this.name
}

output "instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "The connection string for Application Insights"
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "app_id" {
  description = "The App ID associated with the Application Insights resource"
  value       = azurerm_application_insights.this.app_id
}

output "web_test_ids" {
  description = "Map of web test names to their IDs"
  value       = { for k, v in azurerm_application_insights_web_test.this : k => v.id }
}
