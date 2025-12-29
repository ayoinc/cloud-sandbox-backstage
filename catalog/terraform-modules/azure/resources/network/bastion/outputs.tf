output "bastion_id" {
  description = "The ID of the Bastion host"
  value       = azurerm_bastion_host.this.id
}

output "bastion_name" {
  description = "The name of the Bastion host"
  value       = azurerm_bastion_host.this.name
}

output "bastion_dns_name" {
  description = "The DNS name of the Bastion host"
  value       = azurerm_bastion_host.this.dns_name
}

output "public_ip_address" {
  description = "The public IP address of the Bastion host"
  value       = azurerm_public_ip.bastion.ip_address
}
