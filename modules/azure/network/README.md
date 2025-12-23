# Azure Network Module

Terraform module for creating Azure Virtual Networks with subnets, NSGs, and optional NAT Gateway.

## Features

- Virtual Network with customizable address space
- Multiple subnets with service endpoints and delegations
- Network Security Groups with dynamic rules
- NSG to subnet associations
- Optional NAT Gateway with public IP
- Resource group creation (optional)

## Usage

```hcl
module "network" {
  source = "../modules/azure/network"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  vnet_name           = "vnet-myapp-prod"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "snet-app" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "snet-db" = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Sql"]
      delegation = {
        name                       = "postgresql"
        service_delegation_name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    "snet-aks" = {
      address_prefixes  = ["10.0.10.0/22"]
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
  }

  network_security_groups = {
    "nsg-app" = {
      rules = [
        {
          name                       = "AllowHTTPS"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
  }

  nsg_subnet_associations = {
    "app" = {
      subnet_name = "snet-app"
      nsg_name    = "nsg-app"
    }
  }

  enable_nat_gateway = true
  nat_gateway_subnet_associations = {
    "app" = "snet-app"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create_resource_group | Whether to create a new resource group | bool | true | no |
| resource_group_name | Name of the resource group | string | - | yes |
| location | Azure region for resources | string | - | yes |
| vnet_name | Name of the virtual network | string | - | yes |
| address_space | Address space for the virtual network | list(string) | ["10.0.0.0/16"] | no |
| dns_servers | Custom DNS servers | list(string) | [] | no |
| subnets | Map of subnets to create | map(object) | {} | no |
| network_security_groups | Map of NSGs to create | map(object) | {} | no |
| nsg_subnet_associations | Map of NSG to subnet associations | map(object) | {} | no |
| enable_nat_gateway | Whether to create a NAT gateway | bool | false | no |
| nat_idle_timeout | NAT gateway idle timeout in minutes | number | 10 | no |
| availability_zones | Availability zones for NAT gateway public IP | list(string) | ["1"] | no |
| nat_gateway_subnet_associations | Map of subnet names to associate with NAT gateway | map(string) | {} | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | Name of the resource group |
| resource_group_id | ID of the resource group (if created) |
| vnet_id | ID of the virtual network |
| vnet_name | Name of the virtual network |
| vnet_address_space | Address space of the virtual network |
| subnet_ids | Map of subnet names to their IDs |
| subnet_address_prefixes | Map of subnet names to their address prefixes |
| nsg_ids | Map of NSG names to their IDs |
| nat_gateway_id | ID of the NAT gateway (if created) |
| nat_gateway_public_ip | Public IP address of the NAT gateway |
