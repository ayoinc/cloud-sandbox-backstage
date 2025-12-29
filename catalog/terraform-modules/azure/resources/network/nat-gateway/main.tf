terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

locals {
  base_name = "${var.project_name}-${var.environment}-${var.name}"

  default_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_public_ip" "nat" {
  count = var.public_ip_count

  name                = "${local.base_name}-pip-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = var.sku_name
  zones               = length(var.zones) > 0 ? var.zones : null

  tags = local.tags
}

resource "azurerm_public_ip_prefix" "nat" {
  count = var.use_public_ip_prefix ? 1 : 0

  name                = "${local.base_name}-pip-prefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = var.public_ip_prefix_length
  sku                 = var.sku_name
  zones               = length(var.zones) > 0 ? var.zones : null

  tags = local.tags
}

resource "azurerm_nat_gateway" "this" {
  name                    = local.base_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = var.sku_name
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  zones                   = length(var.zones) > 0 ? var.zones : null

  tags = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = var.public_ip_count

  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat[count.index].id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "this" {
  count = var.use_public_ip_prefix ? 1 : 0

  nat_gateway_id      = azurerm_nat_gateway.this.id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  count = length(var.subnet_ids)

  subnet_id      = var.subnet_ids[count.index]
  nat_gateway_id = azurerm_nat_gateway.this.id
}
