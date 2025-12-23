# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Virtual Network is managed by Terraform for the **${{ values.environment }}** environment.

## Configuration

| Setting | Value |
|---------|-------|
| Location | ${{ values.location }} |
| Address Space | ${{ values.addressSpace }} |
| Environment | ${{ values.environment }} |

## Subnets

| Subnet | Purpose | CIDR |
|--------|---------|------|
| snet-public | Public-facing resources (Load Balancers, App Gateways) | /24 |
| snet-private | Private workloads (VMs, App Services) | /24 |
| snet-database | Database services (SQL, CosmosDB) | /24 |
| snet-aks | AKS cluster nodes | /20 |

## Network Security

- **Public NSG**: Allows HTTP/HTTPS inbound
- **Private NSG**: Allows only VNet traffic, denies internet
- **NAT Gateway**: Provides outbound internet for private subnets

## Usage

### Reference in Other Terraform

```hcl
data "azurerm_virtual_network" "main" {
  name                = "vnet-${{ values.name }}-${{ values.environment }}"
  resource_group_name = "rg-${{ values.name }}-${{ values.environment }}"
}

data "azurerm_subnet" "private" {
  name                 = "snet-private"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
}
```

### VNet Peering

To peer with another VNet, add:

```hcl
resource "azurerm_virtual_network_peering" "to_hub" {
  name                      = "peer-to-hub"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.main.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub.id
}
```

## Owner

This resource is owned by **${{ values.owner }}**.
