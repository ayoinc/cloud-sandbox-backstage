# Azure Networking

## Virtual Network Module

Creates Azure Virtual Network with subnets, NSGs, and optional DDoS protection.

### Usage

```hcl
module "vnet" {
  source = "path/to/azure/resources/network/virtual-network"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  project             = "myapp"
  environment         = "prod"
  
  vnet_address_space = ["10.0.0.0/16"]
  
  subnets = {
    default = {
      address_prefixes = ["10.0.1.0/24"]
    }
    aks = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    database = {
      address_prefixes                              = ["10.0.3.0/24"]
      private_endpoint_network_policies_enabled     = false
      private_link_service_network_policies_enabled = false
    }
  }

  enable_ddos_protection = true
  ddos_protection_plan_id = azurerm_network_ddos_protection_plan.main.id

  tags = module.tags.azure_tags
}
```

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_group_name` | string | required | Resource group name |
| `location` | string | required | Azure region |
| `project` | string | required | Project name |
| `environment` | string | required | Environment |
| `vnet_address_space` | list(string) | ["10.0.0.0/16"] | VNet CIDR |
| `dns_servers` | list(string) | [] | Custom DNS servers |
| `subnets` | map(object) | {} | Subnet configurations |
| `enable_ddos_protection` | bool | false | Enable DDoS protection |

### Outputs

| Output | Description |
|--------|-------------|
| `vnet_id` | Virtual Network ID |
| `vnet_name` | Virtual Network name |
| `subnet_ids` | Map of subnet names to IDs |
| `nsg_ids` | Map of NSG names to IDs |

### Subnet Delegation

For Azure services that require subnet delegation:

```hcl
subnets = {
  appservice = {
    address_prefixes = ["10.0.10.0/24"]
    delegation = {
      name = "appservice-delegation"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
  
  containerinstance = {
    address_prefixes = ["10.0.11.0/24"]
    delegation = {
      name = "aci-delegation"
      service_delegation = {
        name    = "Microsoft.ContainerInstance/containerGroups"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}
```
