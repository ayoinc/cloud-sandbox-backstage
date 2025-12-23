# Azure VNet Module

This Terraform module creates and manages Azure Virtual Networks with comprehensive networking features including Hub-Spoke topology support, subnet delegation, service endpoints, network security groups, and integration with Azure Private Link.

## Overview

Azure Virtual Network (VNet) is the fundamental building block for your private network in Azure. VNet enables many types of Azure resources, such as Azure Virtual Machines (VM), to securely communicate with each other, the internet, and on-premises networks.

### Hub-Spoke Topology

Hub-spoke network topology is a way to isolate workloads while sharing common services such as Identity and Security. The hub is a virtual network in Azure that acts as a central point of connectivity to your on-premises network. The spokes are virtual networks that peer with the hub and can be used to isolate workloads.

**Benefits:**
- Cost savings by centralizing services that can be shared by multiple workloads
- Overcome subscription limits by peering virtual networks from different subscriptions to the central hub
- Separation of concerns between central IT (SecOps, InfraOps) and individual workload teams (workload DevOps)

```hcl
# Hub-Spoke Architecture Example
hub_vnet = {
  name            = "hub-vnet"
  address_space   = ["10.0.0.0/16"]
  resource_group  = azurerm_resource_group.hub.name
  location        = "eastus"
}

spoke_vnets = {
  production = {
    peering_name = "spoke-to-hub"
    resource_group = azurerm_resource_group.spoke.name
    address_space = ["10.1.0.0/16"]
  }
}
```

## Features

- **Custom Address Space**: Flexible address space configuration with multiple CIDR blocks
- **Comprehensive Subnet Management**: Create multiple subnets with custom configurations
- **Subnet Delegation**: Enable delegation for Azure PaaS services
- **Network Security Groups**: Built-in NSG creation and association for each subnet
- **Service Endpoints**: Secure connectivity to Azure services over the Azure backbone
- **Private Link Integration**: Support for Private Endpoints and Private Link Services
- **Hub-Spoke Architecture**: Automated VNet peering between hub and spoke networks
- **VPN/ExpressRoute**: Support for hybrid connectivity options
- **Custom DNS**: Configure custom DNS servers for VNet resolution
- **DDoS Protection**: Enable Standard DDoS protection plan

## Architecture

### Hub-Spoke Design Patterns

The hub-spoke architecture includes the following components:

**Hub Virtual Network:**
- Azure Bastion for remote administrative access
- Azure Firewall for centralized security
- VPN Gateway for hybrid connectivity
- Shared services (Active Directory, DNS, NTP)

**Spoke Virtual Networks:**
- Workload isolation
- Application tiers (web, app, data)
- Development, test, and production environments

**Connectivity:**
- VNet peering (transit routing)
- VPN/ExpressRoute for on-premises connectivity
- User-defined routes (UDRs)

```hcl
# VPN Gateway Example
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "hub-vpn-gateway"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = true
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "GatewayIpConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.vnet.subnet_ids["GatewaySubnet"]
  }
}
```

### VNet Peering

VNet peering enables you to connect virtual networks seamlessly. Network traffic between peered virtual networks is private through the Microsoft backbone network.

**Key Features:**
- Peering works across Azure regions (Global VNet Peering)
- No downtime required to create peering
- No VPN gateways or public internet involved
- Low-latency, high-bandwidth connectivity

### VPN/ExpressRoute

**VPN Gateway:**
- Site-to-Site connectivity for on-premises to Azure
- Point-to-Site for remote workers
- VNet-to-VNet connections

**ExpressRoute:**
- Dedicated private connectivity to Azure
- Higher reliability and faster speeds
- Lower latencies than internet-based connections

## Usage

### Simple VNet Implementation

```hcl
module "simple_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                = "simple-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    web = {
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
      nsg_rules = [
        {
          name                       = "Allow_HTTP"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    },
    app = {
      address_prefixes = ["10.0.2.0/24"]
      delegation = {
        name = "functions-delegation"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    },
    data = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
  
  tags = {
    Environment = "development"
    CostCenter  = "engineering"
  }
}
```

### Hub-Spoke with Azure Firewall

```hcl
# Hub Network
module "hub_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                = "hub-vnet"
  resource_group_name = azurerm_resource_group.hub.name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    AzureFirewallSubnet = {
      address_prefixes = ["10.0.0.0/26"]
    }
    AzureBastionSubnet = {
      address_prefixes = ["10.0.1.0/27"]
    }
    GatewaySubnet = {
      address_prefixes = ["10.0.2.0/27"]
    }
    shared = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
  
  enable_ddos_protection_plan = true
  ddos_protection_plan_id     = azurerm_network_ddos_protection_plan.hub.id
}

# Spoke Network - Production
module "spoke_prod_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                = "spoke-prod-vnet"
  resource_group_name = azurerm_resource_group.prod.name
  location            = "eastus"
  address_space       = ["10.1.0.0/16"]
  
  subnets = {
    web = {
      address_prefixes = ["10.1.1.0/24"]
    }
    app = {
      address_prefixes = ["10.1.2.0/24"]
    }
    data = {
      address_prefixes = ["10.1.3.0/24"]
    }
  }
  
  create_peering = true
  peer_with_hub  = {
    hub_vnet_id = module.hub_vnet.vnet_id
    allow_gateway_transit = true
  }
  
  route_tables = {
    web = {
      routes = [{
        name           = "default-via-firewall"
        address_prefix = "0.0.0.0/0"
        next_hop_type  = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.4" # Azure Firewall private IP
      }]
    }
  }
}

# Azure Firewall
resource "azurerm_firewall" "hub" {
  name                = "hub-firewall"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.hub_vnet.subnet_ids["AzureFirewallSubnet"]
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}
```

### AKS-Integrated VNet

```hcl
module "aks_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                = "aks-vnet"
  resource_group_name = azurerm_resource_group.aks.name
  location            = "eastus2"
  address_space       = ["10.100.0.0/16"]
  
  # Separate subnets for AKS system and user node pools
  subnets = {
    aks_system = {
      address_prefixes = ["10.100.0.0/23"]
      delegation = {
        name = "aks-delegation"
        service_delegation = {
          name    = "Microsoft.ContainerService/managedClusters"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
    aks_user = {
      address_prefixes = ["10.100.2.0/23"]
      delegation = {
        name = "aks-delegation"
        service_delegation = {
          name    = "Microsoft.ContainerService/managedClusters"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
    aks_pods = {
      address_prefixes = ["10.100.4.0/22"]  # /22 provides ~1000 IPs for pods
      delegation = {
        name = "aks-delegation"
        service_delegation = {
          name    = "Microsoft.ContainerService/managedClusters"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
    ingress = {
      address_prefixes = ["10.100.8.0/24"]
      nsg_rules = [{
        name                       = "Allow_HTTP_HTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80", "443"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }]
    }
    private_endpoints = {
      address_prefixes = ["10.100.10.0/24"]
      enforce_private_link_endpoint_network_policies = true
    }
  }
  
  # Enable service endpoints for AKS dependencies
  service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
}

# AKS Cluster
data "azurerm_subnet" "aks_system" {
  name                 = "aks_system"
  virtual_network_name = module.aks_vnet.vnet_name
  resource_group_name  = azurerm_resource_group.aks.name
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "aksk8s"

  default_node_pool {
    name            = "system"
    node_count      = 3
    vm_size         = "Standard_D2s_v3"
    vnet_subnet_id  = data.azurerm_subnet.aks_system.id
    pod_subnet_id   = module.aks_vnet.subnet_ids["aks_pods"]
    enable_node_public_ip = false
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    service_cidr    = "10.200.0.0/16"
    dns_service_ip  = "10.200.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }
}
```

## Inputs

### Required Parameters

| Name | Description | Type | Example |
|------|-------------|------|---------|
| `name` | Name of the Virtual Network | `string` | `"production-vnet"` |
| `resource_group_name` | Name of the resource group | `string` | `"rg-network-eastus"` |
| `location` | Azure region | `string` | `"eastus"` |
| `address_space` | VNet address space(s) | `list(string)` | `["10.0.0.0/16", "192.168.0.0/16"]` |

### Optional Parameters

| Name | Description | Type | Default | Example |
|------|-------------|------|---------|---------|
| `subnets` | Map of subnet configurations | `map(object)` | `{}` | See Subnet Configuration |
| `dns_servers` | Custom DNS server addresses | `list(string)` | `[]` | `["10.0.0.4", "10.0.0.5"]` |
| `tags` | Resource tags | `map(string)` | `{}` | `{ Environment = "prod" }` |
| `bgp_community` | BGP community attribute | `string` | `null` | `"12076:10010"` |
| `ddos_protection_plan_id` | DDoS protection plan ID | `string` | `null` | `/subscriptions/.../ddosProtectionPlans/...` |
| `enable_ddos_protection_plan` | Enable DDoS protection | `bool` | `false` | `true` |
| `create_peering` | Create VNet peering | `bool` | `false` | `true` |
| `peer_with_hub` | Hub peering configuration | `object` | `null` | See Peering Configuration |
| `service_endpoints` | Default service endpoints for all subnets | `list(string)` | `[]` | `["Microsoft.Storage"]` |
| `route_tables` | Route tables configuration | `map(object)` | `{}` | See Route Table Configuration |

### Subnet Configuration

```hcl
subnets = {
  subnet_name = {
    address_prefixes = list(string)
    service_endpoints = optional(list(string))
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    }))
    enforce_private_link_endpoint_network_policies = optional(bool)
    enforce_private_link_service_network_policies = optional(bool)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string)
      source_port_ranges         = optional(list(string))
      destination_port_range     = optional(string)
      destination_port_ranges    = optional(list(string))
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(list(string))
      destination_address_prefix = optional(string)
      destination_address_prefixes = optional(list(string))
    })))
  }
}
```

### Peering Configuration

```hcl
peer_with_hub = {
  hub_vnet_id           = string
  allow_forwarded_traffic  = optional(bool, false)
  allow_gateway_transit    = optional(bool, false)
  use_remote_gateways      = optional(bool, false)
}
```

## Outputs

| Name | Description | Usage Example |
|------|-------------|---------------|
| `vnet_id` | Resource ID of the Virtual Network | `module.vnet.vnet_id` |
| `vnet_name` | Name of the Virtual Network | `module.vnet.vnet_name` |
| `address_space` | VNet address space | `module.vnet.address_space` |
| `subnets` | Map of subnet configurations | `module.vnet.subnets` |
| `subnet_ids` | Map of subnet names to resource IDs | `module.vnet.subnet_ids["web"]` |
| `subnet_names` | Map of subnet names | `module.vnet.subnet_names` |
| `nsg_ids` | Map of NSG resource IDs | `module.vnet.nsg_ids["web"]` |
| `peering_id` | VNet peering ID (if enabled) | `module.vnet.peering_id` |

### Working with Outputs

**Private Endpoints:**
```hcl
resource "azurerm_private_endpoint" "storage" {
  name                = "storage-pe"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = module.vnet.subnet_ids["private_endpoints"]
}
```

**AKS Integration:**
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  network_profile {
    vnet_subnet_id = module.vnet.subnet_ids["aks"]
  }
}
```

**Service Endpoints:**
```hcl
resource "azurerm_storage_account" "sa" {
  network_rules {
    virtual_network_subnet_ids = [
      module.vnet.subnet_ids["data"]
    ]
  }
}
```

## Subnet Design

### Address Space Planning

**Best Practices:**
- Use private IP ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- Plan for growth (larger CIDR blocks)
- Consider service-specific requirements
- Reserve space for future expansion
- Account for overlapping with on-premises networks

**Subnet Sizing Examples:**

| Service | Recommended Size | IPs Available | Notes |
|---------|-----------------|---------------|-------|
| GatewaySubnet | /27 or larger | 32+ IPs | Required for VPN/ExpressRoute |
| AzureBastionSubnet | /26 or larger | 64+ IPs | Minimum /26 subnet |
| AzureFirewallSubnet | /26 | 64 IP | Azure Firewall requires /26 |
| Web Tier | /24 | 256 IPs | Public-facing applications |
| App Tier | /24 | 256 IPs | Application servers |
| Data Tier | /24 | 256 IPs | Databases, cache |
| AKS Nodes | /23 | 512 IPs | Node pools |
| AKS Pods | /22 | 1024 IPs | Pod networking (cluster size) |
| Private Endpoints | /24 | 256 IPs | Private Link services |

**Address Space Calculator:**
```bash
# Calculate available IPs in CIDR
python3 -c "import ipaddress; print(list(ipaddress.ip_network('10.0.1.0/24').hosts())[0:5])"

# Azure CLI to validate address space
az network vnet check-ip-address \
  --resource-group rg-network \
  --name vnet-production \
  --ip-address "10.0.1.5"
```

### Subnet Naming Conventions

```hcl
# Environment-based naming
prod-web-tier
prod-app-tier
gateway-subnet
bastion-subnet

# Service-based naming
aks-system-pool
aks-user-pool
private-endpoints
app-service-integration
```

## Service Endpoints

### Which Services to Enable

**Recommended Azure Services:**
- **Microsoft.Storage**: Blob, File, Queue, Table storage
- **Microsoft.Sql**: SQL Database, SQL Managed Instance
- **Microsoft.AzureActiveDirectory**: Azure AD authentication
- **Microsoft.KeyVault**: Key Vault access
- **Microsoft.ContainerRegistry**: ACR for Kubernetes
- **Microsoft.Web**: App Service, Functions

**Security Benefits:**
- Traffic stays on Azure backbone (no public internet exposure)
- Improved latency and performance
- Enhanced security with NSG rules and service tags
- No additional costs for data transfer

```hcl
# Service Endpoints Configuration
subnets = {
  secure = {
    address_prefixes  = ["10.0.3.0/24"]
    service_endpoints = [
      "Microsoft.Storage",
      "Microsoft.Sql",
      "Microsoft.KeyVault",
      "Microsoft.AzureActiveDirectory"
    ]
  }
}
```

### Azure CLI Verification

```bash
# List service endpoints available in region
az network vnet list-endpoint-services \
  --location eastus \
  --query [].name

# Enable service endpoint on existing subnet
az network vnet subnet update \
  --vnet-name vnet-production \
  --resource-group rg-network \
  --name data-subnet \
  --service-endpoints "Microsoft.Storage" "Microsoft.Sql"

# Verify service endpoint status
az network vnet subnet show \
  --vnet-name vnet-production \
  --resource-group rg-network \
  --name data-subnet \
  --query serviceEndpoints
```

## Delegation

### When to Use Subnet Delegation

Subnet delegation enables you to designate a specific subnet for Azure PaaS services that need to inject into your virtual network.

**Common Scenarios:**
- Azure Kubernetes Service (AKS) node pools
- Azure App Service with VNet integration
- Azure Logic Apps
- Azure API Management
- Azure Container Instances (ACI)

### How to Configure Delegation

```hcl
subnets = {
  app_service = {
    address_prefixes = ["10.0.10.0/24"]
    delegation = {
      name = "app-service-delegation"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
  
  functions = {
    address_prefixes = ["10.0.11.0/24"]
    delegation = {
      name = "functions-delegation"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
  
  aci = {
    address_prefixes = ["10.0.12.0/24"]
    delegation = {
      name = "aci-delegation"
      service_delegation = {
        name    = "Microsoft.ContainerInstance/containerGroups"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action",
          "Microsoft.Network/virtualNetworks/subnets/join/action"
        ]
      }
    }
  }
}
```

**Important Notes:**
- Each delegated subnet can only host the specific PaaS service
- NSG rules still apply to delegated subnets
- Route tables are required for App Service VNet integration

## Security

### Network Security Groups (NSGs)

**Default Security Rules:**
- Deny all inbound traffic from internet
- Allow VNet-to-VNet communication
- Allow outbound internet access

**Example NSG Rules:**

```hcl
nsg_rules = [
  # Allow HTTP from Application Gateway
  {
    name                       = "Allow_AppGW_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  },
  # Allow SQL from app tier only
  {
    name                       = "Allow_SQL_From_App"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  },
  # Deny all internet inbound
  {
    name                       = "Deny_Internet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
]
```

### Azure Firewall Integration

```hcl
# Azure Firewall Policy
resource "azurerm_firewall_policy" "hub" {
  name                = "hub-fw-policy"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location

  dns {
    servers       = ["10.0.3.4", "10.0.3.5"]
    proxy_enabled = true
  }

  threat_intelligence_mode = "Alert"
}

# Network Rules for Azure Firewall
resource "azurerm_firewall_policy_rule_collection_group" "net_rules" {
  name               = "network-rules"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  network_rule_collection {
    name     = "app-outbound"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "allow-sql-burst"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["Sql.Burst"]
      destination_ports     = ["1433"]
    }
  }
}
```

### DDoS Protection

Standard DDoS Protection provides enhanced mitigation capabilities and protection metrics.

```hcl
# DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "specialized" {
  name                = "ddos-plan-specialized"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.network.name
}

# Enable DDoS Protection on VNet
module "protected_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                          = "ddos-protected-vnet"
  resource_group_name           = azurerm_resource_group.network.name
  location                      = "eastus"
  address_space                 = ["10.0.0.0/16"]
  enable_ddos_protection_plan   = true
  ddos_protection_plan_id       = azurerm_network_ddos_protection_plan.specialized.id
  
  # Cost: ~$2,900/month per protected VNet
}
```

### Private Endpoints

Private Endpoints provide secure connectivity to Azure PaaS services.

```hcl
# Private Endpoint Subnet
subnets = {
  private_endpoints = {
    address_prefixes                               = ["10.0.50.0/24"]
    enforce_private_link_endpoint_network_policies = true
    service_endpoints = ["Microsoft.Storage"]
  }
}

# Storage Account Private Endpoint
resource "azurerm_private_endpoint" "storage" {
  name                = "storage-account-pe"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = module.vnet.subnet_ids["private_endpoints"]

  private_service_connection {
    name                           = "storage-connection"
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

# Private DNS Zone for Private Endpoints
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  resource_group_name   = var.resource_group
  virtual_network_id    = module.vnet.vnet_id
}
```

## Examples

### Enterprise Hub-Spoke Architecture

```hcl
# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "hub_address_space" {
  description = "Hub VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# Resource Groups
resource "azurerm_resource_group" "network" {
  name     = "rg-network-${var.environment}"
  location = var.location
  tags     = var.tags
}

# DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "ddos" {
  name                = "ddos-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

# Hub VNet
module "hub_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                = "hub-vnet-${var.environment}"
  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  address_space       = var.hub_address_space
  
  subnets = {
    AzureFirewallSubnet = {
      address_prefixes = ["10.0.0.0/26"]
      nsg_rules        = []
    }
    AzureBastionSubnet = {
      address_prefixes = ["10.0.1.0/26"]
    }
    GatewaySubnet = {
      address_prefixes = ["10.0.2.0/27"]
    }
    shared = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
    }
    private_endpoints = {
      address_prefixes                               = ["10.0.4.0/24"]
      enforce_private_link_endpoint_network_policies = true
    }
  }
  
  enable_ddos_protection_plan = true
  ddos_protection_plan_id     = azurerm_network_ddos_protection_plan.ddos.id
  dns_servers                 = ["10.0.3.4", "10.0.3.5"]
  tags                        = var.tags
}

# Spoke VNets for different environments
module "spoke_vnets" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  for_each = var.spoke_environments
  
  name                = "${each.key}-vnet"
  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  address_space       = each.value.address_space
  
  subnets = each.value.subnets
  
  create_peering = true
  peer_with_hub = {
    hub_vnet_id         = module.hub_vnet.vnet_id
    allow_gateway_transit  = true
    allow_forwarded_traffic = true
  }
  
  route_tables = each.value.route_tables
  tags         = merge(var.tags, { Environment = each.key })
}

# VPN Gateway for hybrid connectivity
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "hub-vpn-gateway"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = true
  enable_bgp          = true
  sku                 = "VpnGw2AZ"
  
  ip_configuration {
    name                          = "gateway-ip-config"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.hub_vnet.subnet_ids["GatewaySubnet"]
  }
  
  depends_on = [module.hub_vnet]
}
```

### AKS Networking with Advanced Configurations

```hcl
module "aks_advanced_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                = "aks-advanced-vnet"
  resource_group_name = azurerm_resource_group.aks.name
  location            = "westus2"
  address_space       = ["10.200.0.0/16"]
  
  # Subnets optimized for AKS with separate node pools
  subnets = {
    # System node pool (critical pods)
    system_node_pool = {
      address_prefixes = ["10.200.0.0/23"]     # 512 IPs
      delegation = {
        name = "aks-system-delegation"
        service_delegation = {
          name    = "Microsoft.ContainerService/managedClusters"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
      nsg_rules = [
        {
          name                   = "Allow_AKS_API_Server"
          priority               = 100
          direction              = "Inbound"
          access                 = "Allow"
          protocol               = "Tcp"
          source_port_range      = "*"
          destination_port_range = "443"
          source_address_prefix  = "AzureCloud"
          destination_address_prefix = "*"
        }
      ]
    }
    
    # User node pool (workloads)
    user_node_pool = {
      address_prefixes = ["10.200.2.0/23"]     # 512 IPs
      delegation = {
        name = "aks-user-delegation"
        service_delegation = {
          name    = "Microsoft.ContainerService/managedClusters"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    
    # Dedicated pod subnet (Azure CNI)
    pods_subnet = {
      address_prefixes = ["10.200.4.0/22"]     # 1024 IPs for pods
      delegation = {
        name = "aks-pods-delegation"
        service_delegation = {
          name    = "Microsoft.ContainerService/managedClusters"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    
    # Internal load balancer subnet
    internal_lb = {
      address_prefixes = ["10.200.8.0/24"]     # 256 IPs
      nsg_rules        = []
    }
    
    # Ingress controller (Application Gateway)
    ingress_agw = {
      address_prefixes = ["10.200.9.0/24"]
      nsg_rules = [
        {
          name                      = "Allow_HTTP_HTTPS"
          priority                  = 100
          direction                 = "Inbound"
          access                    = "Allow"
          protocol                  = "Tcp"
          source_port_range         = "*"
          destination_port_ranges   = ["80", "443"]
          source_address_prefix     = "*"
          destination_address_prefix = "*"
        }
      ]
    }
    
    # Private endpoints for AKS dependencies
    private_endpoints = {
      address_prefixes                               = ["10.200.16.0/24"]
      enforce_private_link_endpoint_network_policies = true
      service_endpoints = ["Microsoft.Storage"]
    }
    
    # Azure Bastion for management
    AzureBastionSubnet = {
      address_prefixes = ["10.200.17.0/27"]      # /27 minimum for Bastion
    }
  }
  
  # Enable service endpoints for storage, container registry
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.ContainerRegistry"
  ]
  
  # Custom DNS for private AKS cluster
  dns_servers = ["168.63.129.16"]  # Azure DNS
  
  tags = {
    Environment     = "production"
    Service         = "aks"
    CostCenter      = "platform"
    DataClassification = "confidential"
  }
}
```

### App Service VNet Integration

```hcl
module "app_service_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                = "app-service-vnet"
  resource_group_name = azurerm_resource_group.appservice.name
  location            = "eastus"
  address_space       = ["10.250.0.0/16"]
  
  subnets = {
    # Delegated subnet for App Service
    app_service_delegated = {
      address_prefixes = ["10.250.0.0/24"]
      delegation = {
        name = "app-service-delegation"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
      # Route table required for regional VNet integration
      route_table_required = true
    }
    
    # Private endpoints for App Service dependencies
    app_dependendies = {
      address_prefixes  = ["10.250.1.0/24"]
      service_endpoints = [
        "Microsoft.Sql",
        "Microsoft.Storage",
        "Microsoft.KeyVault"
      ]
    }
    
    # ASE (App Service Environment) subnet
    ase_subnet = {
      address_prefixes = ["10.250.16.0/24"]
      nsg_rules        = []
    }
  }
  
  # Route table for VNet integration
  route_tables = {
    app_service_route_table = {
      routes = [
        {
          name                   = "default-route"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "Internet"
          next_hop_in_ip_address = null
        }
      ]
      disable_bgp_route_propagation = false
    }
  }
}

# App Service Plan with VNet integration
resource "azurerm_app_service_plan" "app_service" {
  name                = "app-service-plan"
  location            = azurerm_resource_group.appservice.location
  resource_group_name = azurerm_resource_group.appservice.name
  kind                = "Linux"
  reserved            = true
  
  sku {
    tier = "Standard"
    size = "S1"
  }
}

# App Service with VNet Integration
resource "azurerm_app_service" "app" {
  name                = "webapp-${var.environment}"
  location            = azurerm_resource_group.appservice.location
  resource_group_name = azurerm_resource_group.appservice.name
  app_service_plan_id = azurerm_app_service_plan.app_service.id
  
  site_config {
    linux_fx_version = "NODE|14-lts"
    always_on        = true
  }
  
  app_settings = {
    "WEBSITE_DNS_SERVER"     = "168.63.129.16"
    "WEBSITE_VNET_ROUTE_ALL" = "1"
  }
}

# VNet Integration Configuration
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_app_service.app.id
  subnet_id      = module.app_service_vnet.subnet_ids["app_service_delegated"]
}
```

## Integration

### Working with Virtual Machines

```hcl
# Linux VM in web subnet
resource "azurerm_linux_virtual_machine" "web" {
  name                = "web-server-vm"
  resource_group_name = azurerm_resource_group.web.name
  location            = var.location
  size                = "Standard_B2s"
  
  network_interface_ids = [
    azurerm_network_interface.web.id
  ]
  
  admin_ssh_key {
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

# Network Interface with NSG association
resource "azurerm_network_interface" "web" {
  name                = "web-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.web.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnet_ids["web"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

# Apply NSG to NIC
resource "azurerm_network_interface_security_group_association" "web" {
  network_interface_id      = azurerm_network_interface.web.id
  network_security_group_id = module.vnet.nsg_ids["web"]
}
```

### AKS Integration with Private Cluster

```hcl
# Private AKS Cluster
resource "azurerm_kubernetes_cluster" "aks_private" {
  name                      = "aks-private-cluster"
  resource_group_name       = azurerm_resource_group.aks.name
  location                  = var.location
  dns_prefix                = "privatek8s"
  private_cluster_enabled   = true
  
  linux_profile {
    admin_username = "adminuser"
    ssh_key {
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }
  
  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
    service_cidr       = "172.100.0.0/16"
    dns_service_ip     = "172.100.0.10"
    docker_bridge_cidr = "172.101.0.1/16"
  }
  
  depends_on = [module.aks_vnet]
}

# Private DNS for AKS management API
resource "azurerm_private_dns_zone" "aks" {
  name                = "${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.aks.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "aks-dns-link"
  resource_group_name   = azurerm_resource_group.aks.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = module.aks_vnet.vnet_id
}
```

### Private DNS Integration

```hcl
# Create Private DNS Zones
resource "azurerm_private_dns_zone" "zones" {
  for_each = toset([
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.database.windows.net",
    "privatelink.keyvault.azure.net",
    "privatelink.azurecontainerregistry.io"
  ])

  name                = each.value
  resource_group_name = azurerm_resource_group.network.name
}

# Link zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = azurerm_private_dns_zone.zones

  name                  = "${each.key}-link"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = each.value
  virtual_network_id    = module.vnet.vnet_id
  registration_enabled  = false
}

# Use Private Endpoints
resource "azurerm_private_endpoint" "storage" {
  name                = "storage-privatelink"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = module.vnet.subnet_ids["private_endpoints"]
  
  private_service_connection {
    name                           = "storage-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  
  depends_on = [azurerm_private_dns_zone_virtual_network_link.links]
}
```

## Pricing

### VNet Costs

**Monthly Pricing (as of 2024):**
- Virtual Network: **FREE** (up to 50 VNets per subscription)
- Subnets: **FREE** (no direct charges for subnets)
- Public IP Addresses: $3-4 per IP/month (Standard SKU)

### Peering Costs

**VNet Peering Pricing:**
- Intra-region: $0.01 per GB (inbound + outbound)
- Inter-region (Global Peering): $0.035 per GB (inbound + outbound)
- Cross-tenant peering supported with additional charges

**Cost Optimization:**
- Consolidate workloads to reduce peering requirements
- Use VPN Gateway for cross-region connectivity (if data transfer is high)

### VPN Gateway

**Gateway Pricing:**
- Basic: $26/month + $0.087 per connection hour
- VpnGw1: $138/month + $0.361 per connection hour
- VpnGw2: $512/month + $0.705 per connection hour
- VpnGw3: $1,104/month + $1.17 per connection hour
- Active-Active: Multiply costs by number of zones

**Data Transfer:**
- First 5 GB/month: FREE
- Additional data: $0.087 per GB

### Azure Firewall

**Firewall Pricing:**
- Standard: $0.736/hour (~$550/month)
- Premium: $2.67/hour (~$1,980/month)
- Data processed: $0.008 per GB

**Cost Optimization:**
- Use Firewall Manager policies
- Implement threat intelligence
- Use forced tunneling for internet traffic
- Evaluate third-party NVAs for cost savings

### DDoS Protection

**Standard DDoS Protection:**
- **$2,944/month** per protected VNet
- No additional charges for attack mitigation

**Free Basic DDoS:**
- Automatically enabled on all public IPs
- Limited to 3 public IPs per VNet

**Cost-Benefit Analysis:**
- Recommended for mission-critical apps
- Evaluate risk vs. cost for smaller environments
- Consider Azure Front Door + WAF as alternative

### Private Link

**Private Endpoint Pricing:**
- Private Endpoint: $0.10/hour (~$73/month)
- Private Link Service: $0.036/hour (~$26/month)
- Data processed: $0.01 per GB

### Cost Calculation Example

```hcl
# Monthly Cost Estimate for Enterprise Hub-Spoke
# Hub VNet with: Azure Firewall, VPN Gateway, DDoS Protection

- Azure Firewall Standard: $550/month
- VPN Gateway VpnGw2: $512/month
- DDoS Protection: $2,944/month
- Public IPs (3 Standard): $12/month
- Peering (Intra-region, 1TB): $80/month
- Private Endpoints (10): $730/month

Total: ~$4,828/month for enterprise hub

# Spoke VNet (with peering only):
- Peering: $80/month (1TB data transfer)
# Total per spoke: $80/month
```

## Troubleshooting

### Common Issues

#### 1. VNet Peering Failures

**Symptoms:**
- Peering status shows "Disconnected"
- Unable to connect between peered VNets
- Latency or packet loss

**Solutions:**
```bash
# Check peering status
az network vnet peering list \
  --resource-group rg-network \
  --vnet-name vnet-hub \
  --query "[?name=='spoke1-to-hub'].{Name:name,State:peeringState,Sync:syncRemoteAddressSpace}"

# Verify address space overlap
az network vnet show \
  --resource-group rg-hub \
  --name vnet-hub \
  --query addressSpace

az network vnet show \
  --resource-group rg-spoke \
  --name vnet-spoke \
  --query addressSpace

# Delete and recreate peering if needed
az network vnet peering delete \
  --resource-group rg-hub \
  --vnet-name vnet-hub \
  --name spoke1-to-hub

# Use Terraform to reapply
terraform apply -target=module.vnet.azurerm_virtual_network_peering.hub_to_spoke
```

#### 2. IP Address Exhaustion

**Symptoms:**
- Unable to create new resources
- "Subnet has insufficient IP addresses" errors
- AKS cluster creation fails

**Solutions:**
```bash
# Check subnet utilization
az network vnet subnet show \
  --vnet-name vnet-production \
  --resource-group rg-network \
  --name web-tier \
  --query "{AvailableIPs:availableIpAddresses,UsedIPs:usedIpAddresses}"

# Expand subnet (delete and recreate with larger CIDR)
# 1. Remove existing resources from subnet
# 2. Delete subnet
# 3. Recreate with larger address space
# 4. Redeploy resources

# Alternative: Add new subnet with larger CIDR
# and migrate workloads gradually

# Azure CLI for AKS subnet resize
az network vnet subnet update \
  --vnet-name vnet-aks \
  --resource-group rg-aks \
  --name pods-subnet \
  --address-prefixes "10.200.4.0/21"  # Expand from /22 to /21
```

**Prevention:**
- Plan for growth (use larger subnets initially)
- Monitor IP utilization with Azure Monitor
- Implement subnet sizing policies
- Use CNI networking for AKS to separate pod IP space

#### 3. Service Endpoint Configuration Issues

**Symptoms:**
- Cannot access Azure services (Storage, SQL)
- "403 Forbidden" errors from Azure services
- NSG rules not working as expected

**Solutions:**
```bash
# Verify service endpoint status
az network vnet subnet show \
  --vnet-name vnet-prod \
  --resource-group rg-network \
  --name data-tier \
  --query serviceEndpoints

# Enable service endpoint if missing
az network vnet subnet update \
  --vnet-name vnet-prod \
  --resource-group rg-network \
  --name data-tier \
  --service-endpoints "Microsoft.Storage" "Microsoft.Sql"

# Check storage account firewall rules
az storage account network-rule list \
  --resource-group rg-data \
  --account-name storageaccountname

# Add network rule for allowed subnet
az storage account network-rule add \
  --resource-group rg-data \
  --account-name storageaccountname \
  --subnet module.vnet.subnet_ids["data"]
```

**Verify with Azure CLI:**
```bash
# Test connectivity from VM in subnet
az vm run-command invoke \
  --resource-group rg-app \
  --name app-vm \
  --command-id RunPowerShellScript \
  --scripts "Test-NetConnection storageaccount.blob.core.windows.net -Port 443"
```

#### 4. Subnet Delegation Issues

**Symptoms:**
- Cannot deploy App Service to delegated subnet
- AKS cluster creation fails
- "Subnet is not delegated" errors

**Solutions:**
```bash
# Check current delegation
az network vnet subnet show \
  --vnet-name vnet-app \
  --resource-group rg-app \
  --name app-service \
  --query delegations

# Verify subnet size for App Service
# Must be /27 or larger for regional VNet integration
# Must be /24 or larger for App Service Environment

# Check for overlapping resources
# Delegated subnets cannot contain other resources

# Redeploy delegation if corrupted
terraform apply -target=module.vnet.azurerm_subnet.subnets
```

#### 5. DNS Resolution Issues

**Symptoms:**
- Private endpoint DNS resolution fails
- Hybrid DNS not working
- Custom DNS server not responding

**Solutions:**
```bash
# Check private DNS zone configuration
az network private-dns zone show \
  --resource-group rg-network \
  --name "privatelink.blob.core.windows.net"

# Verify VNet link to private DNS zone
az network private-dns link vnet show \
  --resource-group rg-network \
  --zone-name "privatelink.blob.core.windows.net" \
  --name "blob-link"

# Test DNS resolution from VM
az vm run-command invoke \
  --resource-group rg-app \
  --name app-vm \
  --command-id RunShellScript \
  --scripts "nslookup storageaccount.blob.core.windows.net"

# Check custom DNS server settings
az network vnet show \
  --name vnet-production \
  --resource-group rg-network \
  --query "dhcpOptions.dnsServers"
```

### Common Azure CLI Commands

```bash
# Network diagnostics
az network watcher connectivity check \
  --source-resource vm-name \
  --resource-group rg-source \
  --dest-resource storage-account \
  --dest-resource-group rg-dest

# Flow logs analysis
az network watcher flow-log show \
  --resource-group rg-network-watcher \
  --nsg nsg-web-tier \
  --query '{enabled:enabled,storageId:storageId}'

# Effective security rules
az network nic list-effective-nsg \
  --resource-group rg-app \
  --name app-vm-nic

# Next hop analysis
az network watcher next-hop show \
  --vm vm-name \
  --resource-group rg-source \
  --source-ip 10.0.1.4 \
  --dest-ip 10.0.2.5
```

## References

### Azure Documentation

- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Hub-Spoke Network Topology](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Firewall Documentation](https://docs.microsoft.com/en-us/azure/firewall/)
- [AKS Networking Concepts](https://docs.microsoft.com/en-us/azure/aks/concepts-network)
- [App Service VNet Integration](https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet)
- [Private Link Documentation](https://docs.microsoft.com/en-us/azure/private-link/)
- [Azure DDoS Protection](https://docs.microsoft.com/en-us/azure/ddos-protection/)

### Related Terraform Modules

- [Azure Bastion Module](https://github.com/company/terraform-modules/tree/main/azure/bastion)
- [Azure VPN Gateway Module](https://github.com/company/terraform-modules/tree/main/azure/vpn-gateway)
- [Azure Firewall Module](https://github.com/company/terraform-modules/tree/main/azure/firewall)
- [AKS Cluster Module](https://github.com/company/terraform-modules/tree/main/azure/aks)
- [App Service Module](https://github.com/company/terraform-modules/tree/main/azure/app-service)
- [Private DNS Module](https://github.com/company/terraform-modules/tree/main/azure/private-dns)

### Security Best Practices

- [Azure Security Benchmark](https://docs.microsoft.com/en-us/azure/security/benchmarks/)
- [Network Security Best Practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/network-best-practices)
- [Azure Firewall Manager](https://docs.microsoft.com/en-us/azure/firewall-manager/)
- [Zero Trust Architecture](https://docs.microsoft.com/en-us/security/zero-trust/)

### Cost Optimization

- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Network Bandwidth Pricing](https://azure.microsoft.com/en-us/pricing/details/bandwidth/)
- [VNet Peering Pricing](https://azure.microsoft.com/en-us/pricing/details/virtual-network/)
- [Azure Firewall Pricing](https://azure.microsoft.com/en-us/pricing/details/azure-firewall/)

### Tools & Utilities

- [Azure Network Watcher](https://docs.microsoft.com/en-us/azure/network-watcher/)
- [Azure Connectivity Test](https://docs.microsoft.com/en-us/azure/network-watcher/network-watcher-connectivity-cli)
- [TCPing for Testing](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-troubleshoot-connectivity-problem-between-vms)
- [Wireshark for Network Analysis](https://www.wireshark.org/)