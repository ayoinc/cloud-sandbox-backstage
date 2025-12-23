output "log_analytics_workspace_ids" {
  value = { for k, v in azurerm_log_analytics_workspace.this : k => v.id }
}

output "log_analytics_workspace_primary_keys" {
  value     = { for k, v in azurerm_log_analytics_workspace.this : k => v.primary_shared_key }
  sensitive = true
}

output "log_analytics_workspace_secondary_keys" {
  value     = { for k, v in azurerm_log_analytics_workspace.this : k => v.secondary_shared_key }
  sensitive = true
}

output "log_analytics_workspace_customer_ids" {
  value = { for k, v in azurerm_log_analytics_workspace.this : k => v.workspace_id }
}

output "application_insights_ids" {
  value = { for k, v in azurerm_application_insights.this : k => v.id }
}

output "application_insights_instrumentation_keys" {
  value     = { for k, v in azurerm_application_insights.this : k => v.instrumentation_key }
  sensitive = true
}

output "application_insights_connection_strings" {
  value     = { for k, v in azurerm_application_insights.this : k => v.connection_string }
  sensitive = true
}

output "action_group_ids" {
  value = { for k, v in azurerm_monitor_action_group.this : k => v.id }
}

output "data_collection_rule_ids" {
  value = { for k, v in azurerm_monitor_data_collection_rule.this : k => v.id }
}

output "private_link_scope_ids" {
  value = { for k, v in azurerm_monitor_private_link_scope.this : k => v.id }
}
