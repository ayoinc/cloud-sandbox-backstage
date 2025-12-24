# =============================================================================
# Azure VNet Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# -----------------------------------------------------------------------------
# Virtual Network Outputs
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the Virtual Network"
  value       = azurerm_virtual_network.main.address_space
}

output "vnet_guid" {
  description = "GUID of the Virtual Network"
  value       = azurerm_virtual_network.main.guid
}

# -----------------------------------------------------------------------------
# Subnet Outputs
# -----------------------------------------------------------------------------

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = azurerm_subnet.public.id
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = azurerm_subnet.public.name
}

output "public_subnet_address_prefixes" {
  description = "Address prefixes of the public subnet"
  value       = azurerm_subnet.public.address_prefixes
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = azurerm_subnet.private.id
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = azurerm_subnet.private.name
}

output "private_subnet_address_prefixes" {
  description = "Address prefixes of the private subnet"
  value       = azurerm_subnet.private.address_prefixes
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "database_subnet_name" {
  description = "Name of the database subnet"
  value       = azurerm_subnet.database.name
}

output "database_subnet_address_prefixes" {
  description = "Address prefixes of the database subnet"
  value       = azurerm_subnet.database.address_prefixes
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "Name of the AKS subnet"
  value       = azurerm_subnet.aks.name
}

output "aks_subnet_address_prefixes" {
  description = "Address prefixes of the AKS subnet"
  value       = azurerm_subnet.aks.address_prefixes
}

# All subnet IDs as a map
output "subnet_ids" {
  description = "Map of all subnet IDs"
  value = {
    public   = azurerm_subnet.public.id
    private  = azurerm_subnet.private.id
    database = azurerm_subnet.database.id
    aks      = azurerm_subnet.aks.id
  }
}

# -----------------------------------------------------------------------------
# Network Security Group Outputs
# -----------------------------------------------------------------------------

output "public_nsg_id" {
  description = "ID of the public Network Security Group"
  value       = azurerm_network_security_group.public.id
}

output "public_nsg_name" {
  description = "Name of the public Network Security Group"
  value       = azurerm_network_security_group.public.name
}

output "private_nsg_id" {
  description = "ID of the private Network Security Group"
  value       = azurerm_network_security_group.private.id
}

output "private_nsg_name" {
  description = "Name of the private Network Security Group"
  value       = azurerm_network_security_group.private.name
}

output "database_nsg_id" {
  description = "ID of the database Network Security Group"
  value       = azurerm_network_security_group.database.id
}

output "database_nsg_name" {
  description = "Name of the database Network Security Group"
  value       = azurerm_network_security_group.database.name
}

# All NSG IDs as a map
output "nsg_ids" {
  description = "Map of all Network Security Group IDs"
  value = {
    public   = azurerm_network_security_group.public.id
    private  = azurerm_network_security_group.private.id
    database = azurerm_network_security_group.database.id
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway Outputs
# -----------------------------------------------------------------------------

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (null if disabled)"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_name" {
  description = "Name of the NAT Gateway (null if disabled)"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.main[0].name : null
}

output "nat_public_ip" {
  description = "Public IP address of the NAT Gateway (null if disabled)"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}

output "nat_public_ip_id" {
  description = "ID of the NAT Gateway public IP (null if disabled)"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat[0].id : null
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "vnet_info" {
  description = "Summary of VNet configuration"
  value = {
    name           = azurerm_virtual_network.main.name
    id             = azurerm_virtual_network.main.id
    address_space  = azurerm_virtual_network.main.address_space
    resource_group = azurerm_resource_group.main.name
    location       = azurerm_resource_group.main.location

    subnets = {
      public = {
        id               = azurerm_subnet.public.id
        name             = azurerm_subnet.public.name
        address_prefixes = azurerm_subnet.public.address_prefixes
      }
      private = {
        id               = azurerm_subnet.private.id
        name             = azurerm_subnet.private.name
        address_prefixes = azurerm_subnet.private.address_prefixes
      }
      database = {
        id               = azurerm_subnet.database.id
        name             = azurerm_subnet.database.name
        address_prefixes = azurerm_subnet.database.address_prefixes
      }
      aks = {
        id               = azurerm_subnet.aks.id
        name             = azurerm_subnet.aks.name
        address_prefixes = azurerm_subnet.aks.address_prefixes
      }
    }

    nat_gateway = var.enable_nat_gateway ? {
      id        = azurerm_nat_gateway.main[0].id
      name      = azurerm_nat_gateway.main[0].name
      public_ip = azurerm_public_ip.nat[0].ip_address
    } : null
  }
}
