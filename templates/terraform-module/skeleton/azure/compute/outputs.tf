# -----------------------------------------------------------------------------
# Azure Compute Module - Outputs
# -----------------------------------------------------------------------------

output "vmss_id" {
  description = "Virtual Machine Scale Set ID"
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "vmss_name" {
  description = "Virtual Machine Scale Set name"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}

output "vmss_unique_id" {
  description = "Virtual Machine Scale Set unique identifier"
  value       = azurerm_linux_virtual_machine_scale_set.main.unique_id
}

output "managed_identity_id" {
  description = "User Assigned Managed Identity ID"
  value       = azurerm_user_assigned_identity.vmss.id
}

output "managed_identity_principal_id" {
  description = "User Assigned Managed Identity Principal ID"
  value       = azurerm_user_assigned_identity.vmss.principal_id
}

output "managed_identity_client_id" {
  description = "User Assigned Managed Identity Client ID"
  value       = azurerm_user_assigned_identity.vmss.client_id
}

output "nsg_id" {
  description = "Network Security Group ID"
  value       = azurerm_network_security_group.vmss.id
}

output "nsg_name" {
  description = "Network Security Group name"
  value       = azurerm_network_security_group.vmss.name
}

output "autoscale_setting_id" {
  description = "Autoscale Setting ID"
  value       = azurerm_monitor_autoscale_setting.vmss.id
}

output "autoscale_setting_name" {
  description = "Autoscale Setting name"
  value       = azurerm_monitor_autoscale_setting.vmss.name
}
