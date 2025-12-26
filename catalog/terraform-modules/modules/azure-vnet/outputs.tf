output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group_name
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the VNet"
  value       = azurerm_virtual_network.main.address_space
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = azurerm_subnet.public[*].id
}

output "public_subnet_names" {
  description = "List of public subnet names"
  value       = azurerm_subnet.public[*].name
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = azurerm_subnet.private[*].id
}

output "private_subnet_names" {
  description = "List of private subnet names"
  value       = azurerm_subnet.private[*].name
}

output "public_nsg_id" {
  description = "ID of the public Network Security Group"
  value       = azurerm_network_security_group.public.id
}

output "private_nsg_id" {
  description = "ID of the private Network Security Group"
  value       = azurerm_network_security_group.private.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}
