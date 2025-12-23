# Azure Compute Module - Outputs

output "linux_vmss_ids" {
  description = "Map of Linux VMSS names to their IDs"
  value       = { for k, v in azurerm_linux_virtual_machine_scale_set.this : k => v.id }
}

output "linux_vmss_identities" {
  description = "Map of Linux VMSS names to their managed identity principal IDs"
  value       = { for k, v in azurerm_linux_virtual_machine_scale_set.this : k => try(v.identity[0].principal_id, null) }
}

output "windows_vmss_ids" {
  description = "Map of Windows VMSS names to their IDs"
  value       = { for k, v in azurerm_windows_virtual_machine_scale_set.this : k => v.id }
}

output "windows_vmss_identities" {
  description = "Map of Windows VMSS names to their managed identity principal IDs"
  value       = { for k, v in azurerm_windows_virtual_machine_scale_set.this : k => try(v.identity[0].principal_id, null) }
}

output "linux_vm_ids" {
  description = "Map of Linux VM names to their IDs"
  value       = { for k, v in azurerm_linux_virtual_machine.this : k => v.id }
}

output "linux_vm_private_ips" {
  description = "Map of Linux VM names to their private IP addresses"
  value       = { for k, v in azurerm_network_interface.linux : k => v.private_ip_address }
}

output "linux_vm_identities" {
  description = "Map of Linux VM names to their managed identity principal IDs"
  value       = { for k, v in azurerm_linux_virtual_machine.this : k => try(v.identity[0].principal_id, null) }
}

output "windows_vm_ids" {
  description = "Map of Windows VM names to their IDs"
  value       = { for k, v in azurerm_windows_virtual_machine.this : k => v.id }
}

output "windows_vm_private_ips" {
  description = "Map of Windows VM names to their private IP addresses"
  value       = { for k, v in azurerm_network_interface.windows : k => v.private_ip_address }
}

output "windows_vm_identities" {
  description = "Map of Windows VM names to their managed identity principal IDs"
  value       = { for k, v in azurerm_windows_virtual_machine.this : k => try(v.identity[0].principal_id, null) }
}
