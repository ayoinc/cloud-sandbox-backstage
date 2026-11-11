locals {
  # The shared modules know the production environment as "prod".
  environment_short = var.environment == "production" ? "prod" : var.environment
  name_prefix       = "${var.project_name}-${local.environment_short}"
  is_production     = var.environment == "production"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  runs_aks            = var.compute_type == "aks"
  runs_vmss           = var.compute_type == "vmss"
  runs_container_apps = var.compute_type == "container-apps"

  # A maximum below the minimum is raised to the minimum.
  max_nodes = max(var.min_nodes, var.max_nodes)

  uses_sql        = var.database_type == "sql-database"
  uses_postgresql = var.database_type == "postgresql"
  uses_cosmos     = var.database_type == "cosmos-db"

  # The address space as its network address, whatever host bits were given.
  vnet_address_space = cidrsubnet(var.vnet_address_space, 0, 0)

  # The gateway, data and ingress subnets are one 256th of the address space
  # each, the application subnet is one 16th.
  subnet_prefixes = {
    gateway = cidrsubnet(local.vnet_address_space, 8, 0)
    data    = cidrsubnet(local.vnet_address_space, 8, 1)
    ingress = cidrsubnet(local.vnet_address_space, 8, 2)
    app     = cidrsubnet(local.vnet_address_space, 4, 1)
  }

  subnets = {
    for name, subnet in {
      gateway = {
        address_prefixes = [local.subnet_prefixes.gateway]
      }

      # A Container Apps environment needs its subnet delegated.
      app = {
        address_prefixes = [local.subnet_prefixes.app]
        delegation = local.runs_container_apps ? {
          name = "container-apps"
          service_delegation = {
            name    = "Microsoft.App/environments"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          }
        } : null
      }

      # A PostgreSQL flexible server lives in a delegated subnet. The other
      # databases are reached through a private endpoint in this subnet.
      data = {
        address_prefixes  = [local.subnet_prefixes.data]
        service_endpoints = local.uses_postgresql ? ["Microsoft.Storage"] : []
        delegation = local.uses_postgresql ? {
          name = "postgresql"
          service_delegation = {
            name    = "Microsoft.DBforPostgreSQL/flexibleServers"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          }
        } : null
      }

      # Holds the internal load balancer of the AKS ingress.
      ingress = {
        address_prefixes = [local.subnet_prefixes.ingress]
      }
    } : name => subnet if name != "ingress" || local.runs_aks
  }

  # The network module creates one network security group per subnet and
  # returns their IDs. Rules are attached by name.
  nsg_names = { for name, id in module.network.nsg_ids : name => reverse(split("/", id))[0] }

  log_retention_days = { dev = 30, staging = 60, production = 90 }[var.environment]
}

module "resource_group" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/core/resource-group?ref=${{ values.moduleRef }}"

  name        = local.name_prefix
  location    = var.location
  project     = var.project_name
  environment = local.environment_short
  tags        = local.common_tags
}

# -----------------------------------------------------------------------------
# Network: one subnet for the Application Gateway, one for the application and
# one for the database.
# -----------------------------------------------------------------------------

module "network" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/network/virtual-network?ref=${{ values.moduleRef }}"

  resource_group_name = module.resource_group.name
  location            = var.location
  project             = var.project_name
  environment         = local.environment_short
  vnet_address_space  = [local.vnet_address_space]
  subnets             = local.subnets
  tags                = local.common_tags
}

# An Application Gateway v2 cannot be created unless Azure can manage it
# through these ports.
resource "azurerm_network_security_rule" "gateway_management" {
  name                        = "AllowGatewayManager"
  resource_group_name         = module.resource_group.name
  network_security_group_name = local.nsg_names["gateway"]
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "GatewayManager"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "65200-65535"
}

# With Front Door enabled, only Front Door may reach the gateway.
#trivy:ignore:AVD-AZU-0047 The Application Gateway is the public entry point of the application when Front Door is not in front of it.
resource "azurerm_network_security_rule" "gateway_web" {
  name                        = "AllowWebTraffic"
  resource_group_name         = module.resource_group.name
  network_security_group_name = local.nsg_names["gateway"]
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = var.enable_front_door ? "AzureFrontDoor.Backend" : "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = local.serves_https ? ["80", "443"] : ["80"]
}

# The database accepts connections from the application subnet only.
resource "azurerm_network_security_rule" "data_from_app" {
  name                        = "AllowApplication"
  resource_group_name         = module.resource_group.name
  network_security_group_name = local.nsg_names["data"]
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefixes     = [local.subnet_prefixes.app, local.subnet_prefixes.data]
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = local.database_ports
}

# The deny rule below would otherwise also stop the health probes of the Azure
# platform, which the VirtualNetwork tag includes.
resource "azurerm_network_security_rule" "data_from_platform" {
  name                        = "AllowAzureLoadBalancer"
  resource_group_name         = module.resource_group.name
  network_security_group_name = local.nsg_names["data"]
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_address_prefix       = "AzureLoadBalancer"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}

resource "azurerm_network_security_rule" "data_deny_other" {
  name                        = "DenyOtherVirtualNetworkTraffic"
  resource_group_name         = module.resource_group.name
  network_security_group_name = local.nsg_names["data"]
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

module "log_analytics" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/log-analytics?ref=${{ values.moduleRef }}"

  resource_group_name       = module.resource_group.name
  location                  = var.location
  project                   = var.project_name
  environment               = local.environment_short
  retention_in_days         = local.log_retention_days
  enable_container_insights = local.runs_aks
  tags                      = local.common_tags
}
