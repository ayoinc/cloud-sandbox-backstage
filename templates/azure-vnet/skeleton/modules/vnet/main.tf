# =============================================================================
# Azure VNet Module
# =============================================================================
# This module creates a complete Azure Virtual Network infrastructure including:
# - Resource Group
# - Virtual Network with configurable address space
# - Subnets: public, private, database, and AKS
# - Network Security Groups with baseline rules
# - NAT Gateway for outbound connectivity (optional)
# =============================================================================

locals {
  # Naming convention: {resource-type}-{name}-{environment}
  resource_group_name = "rg-${var.name}-${var.environment}"
  vnet_name           = "vnet-${var.name}-${var.environment}"
  nat_gateway_name    = "nat-${var.name}-${var.environment}"
  nat_public_ip_name  = "pip-nat-${var.name}-${var.environment}"

  # Common tags applied to all resources
  common_tags = merge(var.tags, {
    Project     = var.name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Subnet configurations
  subnets = {
    public = {
      name              = "snet-public"
      address_prefixes  = [var.public_subnet_cidr]
      service_endpoints = []
      nsg_association   = true
      nsg_type          = "public"
      nat_association   = false
    }
    private = {
      name              = "snet-private"
      address_prefixes  = [var.private_subnet_cidr]
      service_endpoints = []
      nsg_association   = true
      nsg_type          = "private"
      nat_association   = var.enable_nat_gateway
    }
    database = {
      name              = "snet-database"
      address_prefixes  = [var.database_subnet_cidr]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
      nsg_association   = true
      nsg_type          = "private"
      nat_association   = false
    }
    aks = {
      name              = "snet-aks"
      address_prefixes  = [var.aks_subnet_cidr]
      service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
      nsg_association   = false # AKS manages its own NSG
      nsg_type          = null
      nat_association   = var.enable_nat_gateway
    }
  }
}

# =============================================================================
# Resource Group
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# =============================================================================
# Virtual Network
# =============================================================================
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.address_space]

  dns_servers = var.dns_servers

  tags = local.common_tags
}

# =============================================================================
# Subnets
# =============================================================================
resource "azurerm_subnet" "public" {
  name                 = local.subnets.public.name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = local.subnets.public.address_prefixes

  service_endpoints = local.subnets.public.service_endpoints
}

resource "azurerm_subnet" "private" {
  name                 = local.subnets.private.name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = local.subnets.private.address_prefixes

  service_endpoints = local.subnets.private.service_endpoints
}

resource "azurerm_subnet" "database" {
  name                 = local.subnets.database.name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = local.subnets.database.address_prefixes

  service_endpoints = local.subnets.database.service_endpoints
}

resource "azurerm_subnet" "aks" {
  name                 = local.subnets.aks.name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = local.subnets.aks.address_prefixes

  service_endpoints = local.subnets.aks.service_endpoints
}

# =============================================================================
# Network Security Groups
# =============================================================================

# Public NSG - Allows HTTP/HTTPS inbound
resource "azurerm_network_security_group" "public" {
  name                = "nsg-public-${var.name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS inbound
  security_rule {
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

  # Allow HTTP inbound (for redirects to HTTPS)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Azure Load Balancer probes
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

  # Deny all other inbound traffic
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

# Private NSG - Only allows VNet internal traffic
resource "azurerm_network_security_group" "private" {
  name                = "nsg-private-${var.name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow VNet inbound
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

  # Allow Azure Load Balancer probes
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

  # Deny all Internet inbound
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

# Database NSG - Strict access control
resource "azurerm_network_security_group" "database" {
  name                = "nsg-database-${var.name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow SQL from private subnet only
  security_rule {
    name                       = "AllowSQLFromPrivate"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1433", "5432", "3306"]
    source_address_prefix      = var.private_subnet_cidr
    destination_address_prefix = "*"
  }

  # Allow SQL from AKS subnet
  security_rule {
    name                       = "AllowSQLFromAKS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1433", "5432", "3306"]
    source_address_prefix      = var.aks_subnet_cidr
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

# =============================================================================
# NSG Associations
# =============================================================================
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

# =============================================================================
# NAT Gateway (Optional - for outbound connectivity)
# =============================================================================
resource "azurerm_public_ip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = local.nat_public_ip_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = local.common_tags
}

resource "azurerm_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  name                    = local.nat_gateway_name
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_idle_timeout

  zones = var.availability_zones

  tags = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

# Associate NAT Gateway with private subnet
resource "azurerm_subnet_nat_gateway_association" "private" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# Associate NAT Gateway with AKS subnet
resource "azurerm_subnet_nat_gateway_association" "aks" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}
