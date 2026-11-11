# -----------------------------------------------------------------------------
# Azure Network Module - Outputs
# -----------------------------------------------------------------------------

locals {
  tier_subnets = {
    for tier in local.tiers : tier => [
      for i in range(var.subnet_count) : azurerm_subnet.main["${tier}-${i + 1}"]
    ]
  }
}

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
  value       = var.vnet_cidr
}

# First subnet of every tier, for callers that need a single subnet
output "subnet_ids" {
  description = "Map of tier (public, private, database, kubernetes) to the ID of its first subnet"
  value       = { for tier in local.tiers : tier => local.tier_subnets[tier][0].id }
}

# Public Subnets
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.tier_subnets["public"][*].id
}

output "public_subnet_names" {
  description = "List of public subnet names"
  value       = local.tier_subnets["public"][*].name
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = local.subnet_cidrs["public"]
}

# Private Subnets
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.tier_subnets["private"][*].id
}

output "private_subnet_names" {
  description = "List of private subnet names"
  value       = local.tier_subnets["private"][*].name
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = local.subnet_cidrs["private"]
}

# Database Subnets
output "database_subnet_ids" {
  description = "List of database subnet IDs (delegated to PostgreSQL Flexible Server)"
  value       = local.tier_subnets["database"][*].id
}

output "database_subnet_names" {
  description = "List of database subnet names"
  value       = local.tier_subnets["database"][*].name
}

output "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  value       = local.subnet_cidrs["database"]
}

# Kubernetes Subnets
output "kubernetes_subnet_ids" {
  description = "List of kubernetes subnet IDs"
  value       = local.tier_subnets["kubernetes"][*].id
}

output "kubernetes_subnet_names" {
  description = "List of kubernetes subnet names"
  value       = local.tier_subnets["kubernetes"][*].name
}

output "kubernetes_subnet_cidrs" {
  description = "List of kubernetes subnet CIDR blocks"
  value       = local.subnet_cidrs["kubernetes"]
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
  description = "Map of NSG IDs by tier"
  value       = { for tier, nsg in azurerm_network_security_group.main : tier => nsg.id }
}

output "nsg_names" {
  description = "Map of NSG names by tier"
  value       = { for tier, nsg in azurerm_network_security_group.main : tier => nsg.name }
}

# Route Tables
output "route_table_ids" {
  description = "Map of route table IDs by tier (the kubernetes tier has none)"
  value       = local.route_table_ids
}

output "route_table_names" {
  description = "Map of route table names by tier (the kubernetes tier has none)"
  value = {
    public   = azurerm_route_table.public.name
    private  = azurerm_route_table.private.name
    database = azurerm_route_table.database.name
  }
}

output "subnet_map" {
  description = "Map of tier to its subnets, each keyed by subnet name with its ID and CIDR"
  value = {
    for tier in local.tiers : tier => {
      for subnet in local.tier_subnets[tier] : subnet.name => {
        id   = subnet.id
        cidr = subnet.address_prefixes[0]
      }
    }
  }
}
