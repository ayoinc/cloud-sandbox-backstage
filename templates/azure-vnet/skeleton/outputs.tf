# =============================================================================
# Azure VNet - Root Outputs
# =============================================================================
# Expose all outputs from the child module.
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.vnet.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.vnet.resource_group_id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = module.vnet.resource_group_location
}

# -----------------------------------------------------------------------------
# Virtual Network Outputs
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.vnet.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.vnet.vnet_name
}

output "vnet_address_space" {
  description = "Address space of the Virtual Network"
  value       = module.vnet.vnet_address_space
}

output "vnet_guid" {
  description = "GUID of the Virtual Network"
  value       = module.vnet.vnet_guid
}

# -----------------------------------------------------------------------------
# Subnet Outputs
# -----------------------------------------------------------------------------

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vnet.public_subnet_id
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = module.vnet.public_subnet_name
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.vnet.private_subnet_id
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = module.vnet.private_subnet_name
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = module.vnet.database_subnet_id
}

output "database_subnet_name" {
  description = "Name of the database subnet"
  value       = module.vnet.database_subnet_name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.vnet.aks_subnet_id
}

output "aks_subnet_name" {
  description = "Name of the AKS subnet"
  value       = module.vnet.aks_subnet_name
}

output "subnet_ids" {
  description = "Map of all subnet IDs"
  value       = module.vnet.subnet_ids
}

# -----------------------------------------------------------------------------
# Network Security Group Outputs
# -----------------------------------------------------------------------------

output "public_nsg_id" {
  description = "ID of the public Network Security Group"
  value       = module.vnet.public_nsg_id
}

output "private_nsg_id" {
  description = "ID of the private Network Security Group"
  value       = module.vnet.private_nsg_id
}

output "database_nsg_id" {
  description = "ID of the database Network Security Group"
  value       = module.vnet.database_nsg_id
}

output "nsg_ids" {
  description = "Map of all Network Security Group IDs"
  value       = module.vnet.nsg_ids
}

# -----------------------------------------------------------------------------
# NAT Gateway Outputs
# -----------------------------------------------------------------------------

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (null if disabled)"
  value       = module.vnet.nat_gateway_id
}

output "nat_public_ip" {
  description = "Public IP address of the NAT Gateway (null if disabled)"
  value       = module.vnet.nat_public_ip
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "vnet_info" {
  description = "Summary of VNet configuration"
  value       = module.vnet.vnet_info
}
