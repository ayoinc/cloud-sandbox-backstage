# -----------------------------------------------------------------------------
# Azure Network Module - Outputs
# -----------------------------------------------------------------------------

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group (if created)"
  value       = var.resource_group_name == null ? azurerm_resource_group.main[0].id : null
}

# Virtual Network
output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.main.name
}

output "vnet_cidr" {
  description = "Virtual Network CIDR block"
  value       = azurerm_virtual_network.main.address_space[0]
}

# Public Subnets
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = azurerm_subnet.public[*].id
}

output "public_subnet_names" {
  description = "List of public subnet names"
  value       = azurerm_subnet.public[*].name
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = [for subnet in azurerm_subnet.public : subnet.address_prefixes[0]]
}

# Private Subnets
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = azurerm_subnet.private[*].id
}

output "private_subnet_names" {
  description = "List of private subnet names"
  value       = azurerm_subnet.private[*].name
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = [for subnet in azurerm_subnet.private : subnet.address_prefixes[0]]
}

# Database Subnets
output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = azurerm_subnet.database[*].id
}

output "database_subnet_names" {
  description = "List of database subnet names"
  value       = azurerm_subnet.database[*].name
}

output "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  value       = [for subnet in azurerm_subnet.database : subnet.address_prefixes[0]]
}

# NAT Gateway
output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.enable_nat ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_name" {
  description = "NAT Gateway name"
  value       = var.enable_nat ? azurerm_nat_gateway.main[0].name : null
}

output "nat_public_ip" {
  description = "NAT Gateway public IP address"
  value       = var.enable_nat ? azurerm_public_ip.nat[0].ip_address : null
}

output "nat_public_ip_id" {
  description = "NAT Gateway public IP resource ID"
  value       = var.enable_nat ? azurerm_public_ip.nat[0].id : null
}

# Network Security Groups
output "nsg_ids" {
  description = "Map of NSG IDs by type"
  value = {
    public   = azurerm_network_security_group.public.id
    private  = azurerm_network_security_group.private.id
    database = azurerm_network_security_group.database.id
  }
}

output "nsg_names" {
  description = "Map of NSG names by type"
  value = {
    public   = azurerm_network_security_group.public.name
    private  = azurerm_network_security_group.private.name
    database = azurerm_network_security_group.database.name
  }
}

# Route Tables
output "route_table_ids" {
  description = "Map of route table IDs by type"
  value = {
    public   = azurerm_route_table.public.id
    private  = azurerm_route_table.private.id
    database = azurerm_route_table.database.id
  }
}

output "route_table_names" {
  description = "Map of route table names by type"
  value = {
    public   = azurerm_route_table.public.name
    private  = azurerm_route_table.private.name
    database = azurerm_route_table.database.name
  }
}

# Computed values for downstream modules
output "subnet_map" {
  description = "Map of all subnets with their IDs and CIDRs"
  value = {
    public = {
      for idx, subnet in azurerm_subnet.public : subnet.name => {
        id   = subnet.id
        cidr = subnet.address_prefixes[0]
      }
    }
    private = {
      for idx, subnet in azurerm_subnet.private : subnet.name => {
        id   = subnet.id
        cidr = subnet.address_prefixes[0]
      }
    }
    database = {
      for idx, subnet in azurerm_subnet.database : subnet.name => {
        id   = subnet.id
        cidr = subnet.address_prefixes[0]
      }
    }
  }
}
