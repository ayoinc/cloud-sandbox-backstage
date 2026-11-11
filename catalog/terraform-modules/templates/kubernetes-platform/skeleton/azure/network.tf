locals {
  is_production = var.environment == "production"

  # The modules of cloud-sandbox-backstage name resources <type>-<project>-<environment>-<location> and know the
  # production environment as prod.
  module_environment = local.is_production ? "prod" : var.environment

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  node_subnet_cidr = cidrsubnet(var.vnet_cidr, 4, 0)
}

module "resource_group" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/core/resource-group?ref=${{ values.moduleRef }}"

  name        = "${var.project_name}-${local.module_environment}"
  location    = var.location
  project     = var.project_name
  environment = local.module_environment
  tags        = local.common_tags
}

# -----------------------------------------------------------------------------
# Network: a virtual network with one subnet for the nodes. Pods get their
# addresses from an overlay range (var.pod_cidr), so the subnet only has to hold
# the nodes and internal load balancers.
# -----------------------------------------------------------------------------

module "network" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/network/virtual-network?ref=${{ values.moduleRef }}"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  project             = var.project_name
  environment         = local.module_environment
  vnet_address_space  = [var.vnet_cidr]

  subnets = {
    aks = {
      address_prefixes = [local.node_subnet_cidr]
    }
  }

  tags = local.common_tags
}

locals {
  # The network module attaches a network security group without rules to the subnet and returns its ID.
  node_nsg_name = reverse(split("/", module.network.nsg_ids["aks"]))[0]
}

# Overlay pod addresses are not part of the virtual network, so the default rules of the network security group
# would drop traffic between nodes and pods.
resource "azurerm_network_security_rule" "cluster_internal" {
  name                        = "AllowNodesAndPods"
  resource_group_name         = module.resource_group.name
  network_security_group_name = local.node_nsg_name

  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "*"
  source_address_prefixes      = [local.node_subnet_cidr, var.pod_cidr]
  source_port_range            = "*"
  destination_address_prefixes = [local.node_subnet_cidr, var.pod_cidr]
  destination_port_range       = "*"
}

# The ingress controller is published through a public load balancer, which hands requests to the nodes with the
# client's address as source. Without an ingress controller nothing in the subnet is reachable from the internet.
#trivy:ignore:AVD-AZU-0047 Ports 80 and 443 of the ingress controller are the public entry point of the platform.
resource "azurerm_network_security_rule" "ingress_web" {
  count = var.ingress_controller != "none" ? 1 : 0

  name                        = "AllowWebFromInternet"
  resource_group_name         = module.resource_group.name
  network_security_group_name = local.node_nsg_name

  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "Internet"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_ranges    = ["80", "443"]
}
