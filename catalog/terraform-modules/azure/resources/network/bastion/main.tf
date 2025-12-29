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
  default_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_public_ip" "bastion" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_bastion_host" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  scale_units         = var.sku == "Standard" ? var.scale_units : 2

  copy_paste_enabled     = var.copy_paste_enabled
  file_copy_enabled      = var.sku == "Standard" ? var.file_copy_enabled : false
  ip_connect_enabled     = var.sku == "Standard" ? var.ip_connect_enabled : false
  shareable_link_enabled = var.sku == "Standard" ? var.shareable_link_enabled : false
  tunneling_enabled      = var.sku == "Standard" ? var.tunneling_enabled : false

  ip_configuration {
    name                 = "bastion-ip-configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = merge(local.default_tags, var.tags)
}
