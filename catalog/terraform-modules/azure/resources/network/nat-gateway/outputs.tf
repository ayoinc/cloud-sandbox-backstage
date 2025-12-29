output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = azurerm_nat_gateway.this.id
}

output "nat_gateway_name" {
  description = "The name of the NAT Gateway"
  value       = azurerm_nat_gateway.this.name
}

output "public_ip_addresses" {
  description = "A list of public IP addresses associated with the NAT Gateway"
  value       = [for pip in azurerm_public_ip.nat : pip.ip_address]
}

output "public_ip_prefix_id" {
  description = "The ID of the public IP prefix, if created"
  value       = var.use_public_ip_prefix ? azurerm_public_ip_prefix.nat[0].id : null
}

output "resource_guid" {
  description = "The resource GUID of the NAT Gateway"
  value       = azurerm_nat_gateway.this.resource_guid
}
