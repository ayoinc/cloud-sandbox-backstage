output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = azurerm_firewall.this.id
}

output "firewall_name" {
  description = "Name of the Azure Firewall"
  value       = azurerm_firewall.this.name
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_policy_id" {
  description = "ID of the Azure Firewall Policy"
  value       = azurerm_firewall_policy.this.id
}
