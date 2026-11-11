# -----------------------------------------------------------------------------
# Azure Network Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Tiers occupy consecutive blocks of subnet_count subnets inside the VNet.
  tiers = ["public", "private", "database", "kubernetes"]
  subnet_cidrs = {
    for tier_index, tier in local.tiers : tier => [
      for i in range(var.subnet_count) : cidrsubnet(var.vnet_cidr, var.subnet_newbits, tier_index * var.subnet_count + i)
    ]
  }

  service_endpoints = {
    public     = ["Microsoft.KeyVault", "Microsoft.Storage"]
    private    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Sql", "Microsoft.Storage"]
    database   = ["Microsoft.Storage"]
    kubernetes = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Sql", "Microsoft.Storage"]
  }

  application_cidrs = concat(local.subnet_cidrs["private"], local.subnet_cidrs["kubernetes"])

  # Inbound rules per tier. Each tier NSG ends with an explicit deny so that
  # the platform default "allow VirtualNetwork" rule does not apply.
  allow_load_balancer = {
    priority    = 200
    access      = "Allow"
    protocol    = "*"
    ports       = ["*"]
    source      = "AzureLoadBalancer"
    sources     = null
    destination = "*"
  }
  deny_all_inbound = {
    priority    = 4096
    access      = "Deny"
    protocol    = "*"
    ports       = ["*"]
    source      = "*"
    sources     = null
    destination = "*"
  }
  allow_vnet_inbound = {
    priority    = 100
    access      = "Allow"
    protocol    = "*"
    ports       = ["*"]
    source      = "VirtualNetwork"
    sources     = null
    destination = "VirtualNetwork"
  }

  nsg_rules = merge(
    {
      for name, rule in {
        "public/AllowPublicIngress" = {
          priority    = 100
          access      = "Allow"
          protocol    = "Tcp"
          ports       = [for port in var.public_ingress_ports : tostring(port)]
          source      = null
          sources     = var.public_ingress_cidrs
          destination = "*"
        }
      } : name => rule if length(var.public_ingress_cidrs) > 0 && length(var.public_ingress_ports) > 0
    },
    {
      "public/AllowAzureLoadBalancer" = local.allow_load_balancer
      "public/DenyAllInbound"         = local.deny_all_inbound

      "private/AllowVnetInbound"       = local.allow_vnet_inbound
      "private/AllowAzureLoadBalancer" = local.allow_load_balancer
      "private/DenyAllInbound"         = local.deny_all_inbound

      "database/AllowDatabaseFromApplications" = {
        priority    = 100
        access      = "Allow"
        protocol    = "Tcp"
        ports       = [for port in var.database_ports : tostring(port)]
        source      = null
        sources     = local.application_cidrs
        destination = "*"
      }
      "database/DenyAllInbound" = local.deny_all_inbound

      # The kubernetes tier keeps the platform default rules below these two,
      # so traffic admitted by AKS-managed load balancer rules still arrives.
      "kubernetes/AllowVnetInbound"       = local.allow_vnet_inbound
      "kubernetes/AllowAzureLoadBalancer" = local.allow_load_balancer
    }
  )

  # Subnets are keyed "<tier>-<n>" so adding a subnet never renumbers others.
  subnets = merge([
    for tier in local.tiers : {
      for i, cidr in local.subnet_cidrs[tier] : "${tier}-${i + 1}" => {
        tier = tier
        cidr = cidr
      }
    }
  ]...)

  nat_subnet_keys   = [for key, subnet in local.subnets : key if contains(["private", "kubernetes"], subnet.tier)]
  route_subnet_keys = [for key, subnet in local.subnets : key if subnet.tier != "kubernetes"]
}

# -----------------------------------------------------------------------------
# Resource Group (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  count = var.resource_group_name == null ? 1 : 0

  name     = "rg-${local.name_prefix}-network"
  location = var.location

  tags = local.common_tags
}

locals {
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : azurerm_resource_group.main[0].name
}

# -----------------------------------------------------------------------------
# Virtual Network
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}"
  resource_group_name = local.resource_group_name
  location            = var.location
  address_space       = [var.vnet_cidr]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "main" {
  for_each = local.subnets

  name                 = "snet-${local.name_prefix}-${each.key}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr]

  service_endpoints = var.enable_service_endpoints ? local.service_endpoints[each.value.tier] : []

  # Database subnets are reserved for PostgreSQL Flexible Server VNet integration.
  dynamic "delegation" {
    for_each = each.value.tier == "database" ? [1] : []

    content {
      name = "postgresql-flexible-server"

      service_delegation {
        name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------------------------

resource "azurerm_public_ip" "nat" {
  count = var.enable_nat ? 1 : 0

  name                = "pip-${local.name_prefix}-nat"
  resource_group_name = local.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.enable_zone_redundancy ? ["1", "2", "3"] : null

  tags = local.common_tags
}

resource "azurerm_nat_gateway" "main" {
  count = var.enable_nat ? 1 : 0

  name                    = "ng-${local.name_prefix}"
  resource_group_name     = local.resource_group_name
  location                = var.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_idle_timeout

  tags = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.enable_nat ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = var.enable_nat ? toset(local.nat_subnet_keys) : toset([])

  subnet_id      = azurerm_subnet.main[each.value].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id

  depends_on = [azurerm_nat_gateway_public_ip_association.main]
}

# -----------------------------------------------------------------------------
# Network Security Groups
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "main" {
  for_each = toset(local.tiers)

  name                = "nsg-${local.name_prefix}-${each.value}"
  resource_group_name = local.resource_group_name
  location            = var.location

  tags = local.common_tags
}

resource "azurerm_network_security_rule" "inbound" {
  for_each = local.nsg_rules

  name                        = split("/", each.key)[1]
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[split("/", each.key)[0]].name

  priority                   = each.value.priority
  direction                  = "Inbound"
  access                     = each.value.access
  protocol                   = each.value.protocol
  source_port_range          = "*"
  destination_port_range     = length(each.value.ports) == 1 ? each.value.ports[0] : null
  destination_port_ranges    = length(each.value.ports) == 1 ? null : each.value.ports
  source_address_prefix      = each.value.source
  source_address_prefixes    = each.value.sources
  destination_address_prefix = each.value.destination
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = local.subnets

  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.value.tier].id

  # Rules are in place before the NSG starts filtering the subnet.
  depends_on = [azurerm_network_security_rule.inbound]
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

resource "azurerm_route_table" "public" {
  name                = "rt-${local.name_prefix}-public"
  resource_group_name = local.resource_group_name
  location            = var.location

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = local.common_tags
}

resource "azurerm_route_table" "private" {
  name                = "rt-${local.name_prefix}-private"
  resource_group_name = local.resource_group_name
  location            = var.location

  route {
    name           = "to-vnet"
    address_prefix = var.vnet_cidr
    next_hop_type  = "VnetLocal"
  }

  tags = local.common_tags
}

# Database subnets only talk to the VNet, so routes learned over BGP from
# on-premises gateways are not propagated to them.
resource "azurerm_route_table" "database" {
  name                          = "rt-${local.name_prefix}-database"
  resource_group_name           = local.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = false

  route {
    name           = "to-vnet"
    address_prefix = var.vnet_cidr
    next_hop_type  = "VnetLocal"
  }

  tags = local.common_tags
}

locals {
  route_table_ids = {
    public   = azurerm_route_table.public.id
    private  = azurerm_route_table.private.id
    database = azurerm_route_table.database.id
  }
}

# The kubernetes tier has no route table: AKS manages routes for its own
# network plugins and rejects tables it does not own when using kubenet.
resource "azurerm_subnet_route_table_association" "main" {
  for_each = toset(local.route_subnet_keys)

  subnet_id      = azurerm_subnet.main[each.value].id
  route_table_id = local.route_table_ids[local.subnets[each.value].tier]
}
