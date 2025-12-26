# -----------------------------------------------------------------------------
# Azure Network Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Calculate subnet CIDRs dynamically
  public_subnet_cidrs   = [for i in range(var.subnet_count) : cidrsubnet(var.vnet_cidr, 4, i)]
  private_subnet_cidrs  = [for i in range(var.subnet_count) : cidrsubnet(var.vnet_cidr, 4, i + var.subnet_count)]
  database_subnet_cidrs = [for i in range(var.subnet_count) : cidrsubnet(var.vnet_cidr, 4, i + (var.subnet_count * 2))]
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
# Subnets - Public
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "public" {
  count = var.subnet_count

  name                 = "snet-${local.name_prefix}-public-${count.index + 1}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.public_subnet_cidrs[count.index]]

  service_endpoints = var.enable_service_endpoints ? [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ] : []
}

# -----------------------------------------------------------------------------
# Subnets - Private
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "private" {
  count = var.subnet_count

  name                 = "snet-${local.name_prefix}-private-${count.index + 1}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.private_subnet_cidrs[count.index]]

  service_endpoints = var.enable_service_endpoints ? [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.ContainerRegistry"
  ] : []
}

# -----------------------------------------------------------------------------
# Subnets - Database
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "database" {
  count = var.subnet_count

  name                 = "snet-${local.name_prefix}-database-${count.index + 1}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.database_subnet_cidrs[count.index]]

  service_endpoints = var.enable_service_endpoints ? [
    "Microsoft.Sql",
    "Microsoft.Storage"
  ] : []

  delegation {
    name = "fs-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
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

  zones = var.enable_zone_redundancy ? ["1"] : null

  tags = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.enable_nat ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

# Associate NAT Gateway with private subnets
resource "azurerm_subnet_nat_gateway_association" "private" {
  count = var.enable_nat ? var.subnet_count : 0

  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# Associate NAT Gateway with database subnets
resource "azurerm_subnet_nat_gateway_association" "database" {
  count = var.enable_nat ? var.subnet_count : 0

  subnet_id      = azurerm_subnet.database[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# -----------------------------------------------------------------------------
# Network Security Groups
# -----------------------------------------------------------------------------

# Public Subnet NSG
resource "azurerm_network_security_group" "public" {
  name                = "nsg-${local.name_prefix}-public"
  resource_group_name = local.resource_group_name
  location            = var.location

  # Allow HTTP inbound
  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS inbound
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Azure Load Balancer
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Private Subnet NSG
resource "azurerm_network_security_group" "private" {
  name                = "nsg-${local.name_prefix}-private"
  resource_group_name = local.resource_group_name
  location            = var.location

  # Allow traffic from VNet
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Database Subnet NSG
resource "azurerm_network_security_group" "database" {
  name                = "nsg-${local.name_prefix}-database"
  resource_group_name = local.resource_group_name
  location            = var.location

  # Allow PostgreSQL from private subnets
  security_rule {
    name                       = "AllowPostgreSQLFromPrivate"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefixes    = local.private_subnet_cidrs
    destination_address_prefix = "*"
  }

  # Allow MySQL from private subnets
  security_rule {
    name                       = "AllowMySQLFromPrivate"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefixes    = local.private_subnet_cidrs
    destination_address_prefix = "*"
  }

  # Allow SQL Server from private subnets
  security_rule {
    name                       = "AllowSQLServerFromPrivate"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefixes    = local.private_subnet_cidrs
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# NSG Associations
# -----------------------------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "public" {
  count = var.subnet_count

  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count = var.subnet_count

  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  count = var.subnet_count

  subnet_id                 = azurerm_subnet.database[count.index].id
  network_security_group_id = azurerm_network_security_group.database.id
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

resource "azurerm_route_table" "public" {
  name                          = "rt-${local.name_prefix}-public"
  resource_group_name           = local.resource_group_name
  location                      = var.location
  disable_bgp_route_propagation = false

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = local.common_tags
}

resource "azurerm_route_table" "private" {
  name                          = "rt-${local.name_prefix}-private"
  resource_group_name           = local.resource_group_name
  location                      = var.location
  disable_bgp_route_propagation = false

  # Default route to VNet for internal traffic
  route {
    name           = "to-vnet"
    address_prefix = var.vnet_cidr
    next_hop_type  = "VnetLocal"
  }

  tags = local.common_tags
}

resource "azurerm_route_table" "database" {
  name                          = "rt-${local.name_prefix}-database"
  resource_group_name           = local.resource_group_name
  location                      = var.location
  disable_bgp_route_propagation = true

  # Database subnets should only communicate within VNet
  route {
    name           = "to-vnet"
    address_prefix = var.vnet_cidr
    next_hop_type  = "VnetLocal"
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------

resource "azurerm_subnet_route_table_association" "public" {
  count = var.subnet_count

  subnet_id      = azurerm_subnet.public[count.index].id
  route_table_id = azurerm_route_table.public.id
}

resource "azurerm_subnet_route_table_association" "private" {
  count = var.subnet_count

  subnet_id      = azurerm_subnet.private[count.index].id
  route_table_id = azurerm_route_table.private.id
}

resource "azurerm_subnet_route_table_association" "database" {
  count = var.subnet_count

  subnet_id      = azurerm_subnet.database[count.index].id
  route_table_id = azurerm_route_table.database.id
}
