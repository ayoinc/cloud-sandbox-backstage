/**
 * Azure Virtual Network Module
 * 
 * Creates a production-ready VNet with:
 * - Multiple subnets across the VNet
 * - Network Security Groups
 * - Route tables
 * - NAT Gateway (optional)
 * - VNet peering support
 * - Service endpoints
 */

#------------------------------------------------------------------------------
# Resource Group (Optional - can use existing)
#------------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name != "" ? var.resource_group_name : "${var.name}-rg"
  location = var.location

  tags = local.common_tags
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.main[0].name : var.resource_group_name

  common_tags = merge(var.tags, {
    Module      = "azure-vnet"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

#------------------------------------------------------------------------------
# Virtual Network
#------------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-vnet"
  location            = var.location
  resource_group_name = local.resource_group_name
  address_space       = var.address_space

  dns_servers = var.dns_servers

  tags = merge(local.common_tags, {
    Name = "${var.name}-vnet"
  })
}

#------------------------------------------------------------------------------
# Subnets
#------------------------------------------------------------------------------
resource "azurerm_subnet" "public" {
  count = length(var.public_subnets)

  name                 = "${var.name}-public-${count.index + 1}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnets[count.index]]

  service_endpoints = var.public_subnet_service_endpoints
}

resource "azurerm_subnet" "private" {
  count = length(var.private_subnets)

  name                 = "${var.name}-private-${count.index + 1}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnets[count.index]]

  service_endpoints = var.private_subnet_service_endpoints

  # Disable private endpoint network policies for private link
  private_endpoint_network_policies = var.enable_private_endpoints ? "Disabled" : "Enabled"
}

#------------------------------------------------------------------------------
# Network Security Groups
#------------------------------------------------------------------------------
resource "azurerm_network_security_group" "public" {
  name                = "${var.name}-public-nsg"
  location            = var.location
  resource_group_name = local.resource_group_name

  # Allow HTTP
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH from VNet only
  security_rule {
    name                       = "AllowSSHFromVNet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "private" {
  name                = "${var.name}-private-nsg"
  location            = var.location
  resource_group_name = local.resource_group_name

  # Allow all traffic from VNet
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Deny all internet inbound
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "public" {
  count = length(azurerm_subnet.public)

  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count = length(azurerm_subnet.private)

  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.private.id
}

#------------------------------------------------------------------------------
# NAT Gateway (Optional)
#------------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = "${var.name}-nat-pip"
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = local.common_tags
}

resource "azurerm_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  name                    = "${var.name}-nat-gw"
  location                = var.location
  resource_group_name     = local.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = var.availability_zones

  tags = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count = var.enable_nat_gateway ? length(azurerm_subnet.private) : 0

  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

#------------------------------------------------------------------------------
# Route Tables
#------------------------------------------------------------------------------
resource "azurerm_route_table" "public" {
  name                = "${var.name}-public-rt"
  location            = var.location
  resource_group_name = local.resource_group_name

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = local.common_tags
}

resource "azurerm_route_table" "private" {
  name                = "${var.name}-private-rt"
  location            = var.location
  resource_group_name = local.resource_group_name

  # Routes are added dynamically based on NAT Gateway or other configurations
  tags = local.common_tags
}

resource "azurerm_subnet_route_table_association" "public" {
  count = length(azurerm_subnet.public)

  subnet_id      = azurerm_subnet.public[count.index].id
  route_table_id = azurerm_route_table.public.id
}

resource "azurerm_subnet_route_table_association" "private" {
  count = length(azurerm_subnet.private)

  subnet_id      = azurerm_subnet.private[count.index].id
  route_table_id = azurerm_route_table.private.id
}

#------------------------------------------------------------------------------
# Bastion Subnet (Optional)
#------------------------------------------------------------------------------
resource "azurerm_subnet" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                 = "AzureBastionSubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_public_ip" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                = "${var.name}-bastion-pip"
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_bastion_host" "main" {
  count = var.enable_bastion ? 1 : 0

  name                = "${var.name}-bastion"
  location            = var.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# VNet Diagnostics (Optional)
#------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  count = var.enable_diagnostics && var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${var.name}-vnet-diag"
  target_resource_id         = azurerm_virtual_network.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
