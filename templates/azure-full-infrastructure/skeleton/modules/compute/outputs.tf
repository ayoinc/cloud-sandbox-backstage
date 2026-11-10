output "vm_ids" {
  description = "Virtual machine IDs"
  value       = azurerm_linux_virtual_machine.main[*].id
}

output "vm_names" {
  description = "Virtual machine names"
  value       = azurerm_linux_virtual_machine.main[*].name
}

output "vm_private_ips" {
  description = "Private IP addresses of the virtual machines"
  value       = azurerm_network_interface.main[*].private_ip_address
}

output "auto_shutdown_enabled" {
  description = "Whether the virtual machines shut down daily"
  value       = length(azurerm_dev_test_global_vm_shutdown_schedule.main) > 0
}

output "generated_ssh_private_key" {
  description = "Private key generated for the administrator (unused when admin_ssh_public_key is set)"
  value       = tls_private_key.ssh.private_key_openssh
  sensitive   = true
}
