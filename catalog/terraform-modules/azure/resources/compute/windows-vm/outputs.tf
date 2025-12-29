output "vm_id" {
  description = "Resource ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.this.name
}

output "private_ip_address" {
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of the virtual machine (if assigned)"
  value       = azurerm_windows_virtual_machine.this.public_ip_address
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = var.enable_system_identity ? azurerm_windows_virtual_machine.this.identity[0].principal_id : null
}
