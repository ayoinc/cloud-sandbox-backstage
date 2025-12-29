output "service_plan_id" {
  description = "ID of the service plan"
  value       = azurerm_service_plan.this.id
}

output "function_app_id" {
  description = "ID of the function app"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.this[0].id : azurerm_windows_function_app.this[0].id
}

output "function_app_name" {
  description = "Name of the function app"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.this[0].name : azurerm_windows_function_app.this[0].name
}

output "default_hostname" {
  description = "Default hostname of the function app"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.this[0].default_hostname : azurerm_windows_function_app.this[0].default_hostname
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = var.enable_system_identity ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].identity[0].principal_id : azurerm_windows_function_app.this[0].identity[0].principal_id) : null
}
