# -----------------------------------------------------------------------------
# Virtual network with a public and a private subnet
# -----------------------------------------------------------------------------

variable "network_cidr" {
  description = "Address space of the virtual network. Subnets are /4 slices of it, so it can be at most a /24."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrsubnet(var.network_cidr, 8, 0))
    error_message = "network_cidr must be a valid IPv4 CIDR block with a prefix of /24 or shorter."
  }
}

variable "enable_nat_gateway" {
  description = "Give the private subnet outbound internet access through a NAT gateway."
  type        = bool
  default     = true
}

resource "azurerm_virtual_network" "this" {
  name                = module.naming.standard["vnet"]
  resource_group_name = local.resource_group_name
  location            = var.region
  address_space       = [var.network_cidr]

  tags = module.tagging.tags
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.network_cidr, 4, 0)]
}

# Azure's implicit outbound access is switched off; the NAT gateway is the
# only way out of the private subnet.
resource "azurerm_subnet" "private" {
  name                            = "private"
  resource_group_name             = local.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [cidrsubnet(var.network_cidr, 4, 8)]
  default_outbound_access_enabled = false
}

# An empty security group allows traffic inside the virtual network and
# denies everything from the internet.
resource "azurerm_network_security_group" "this" {
  name                = "${module.naming.standard["vnet"]}-nsg"
  resource_group_name = local.resource_group_name
  location            = var.region

  tags = module.tagging.tags
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = "${module.naming.standard["vnet"]}-nat-ip"
  resource_group_name = local.resource_group_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = module.tagging.tags
}

resource "azurerm_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = "${module.naming.standard["vnet"]}-nat"
  resource_group_name = local.resource_group_name
  location            = var.region
  sku_name            = "Standard"

  tags = module.tagging.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = azurerm_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet."
  value       = azurerm_subnet.private.id
}
