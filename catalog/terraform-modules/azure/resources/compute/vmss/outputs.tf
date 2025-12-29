output "vmss_id" {
  description = "The ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.this.id
}

output "vmss_name" {
  description = "The name of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.this.name
}

output "unique_id" {
  description = "The unique ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.this.unique_id
}

output "identity_principal_id" {
  description = "The Principal ID of the system-assigned managed identity"
  value       = var.enable_system_identity ? azurerm_linux_virtual_machine_scale_set.this.identity[0].principal_id : null
}

output "autoscale_setting_id" {
  description = "The ID of the autoscale setting"
  value       = var.enable_autoscale ? azurerm_monitor_autoscale_setting.this[0].id : null
}
