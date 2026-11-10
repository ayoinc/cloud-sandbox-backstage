output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Subnet IDs keyed by subnet name"
  value       = { for name, subnet in azurerm_subnet.main : name => subnet.id }
}

output "nsg_ids" {
  description = "Network security group IDs keyed by subnet name"
  value       = { for name, nsg in azurerm_network_security_group.main : name => nsg.id }
}

output "nat_gateway_id" {
  description = "NAT gateway ID (null when disabled)"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "bastion_id" {
  description = "Bastion host ID (null when disabled)"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].id : null
}
