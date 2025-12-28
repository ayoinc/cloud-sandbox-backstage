# =============================================================================
# NETWORKING MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }
variable "vnet_address_space" { type = list(string) }
variable "subnets" {
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
}
variable "enable_ddos_protection" { type = bool; default = false }

locals {
  vnet_name = "vnet-${var.project}-${var.environment}-${var.location}"
}

resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = "snet-${each.key}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

resource "azurerm_network_security_group" "subnet_nsgs" {
  for_each = var.subnets

  name                = "nsg-${each.key}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnet_nsgs[each.key].id
}

output "vnet_id" { value = azurerm_virtual_network.main.id }
output "vnet_name" { value = azurerm_virtual_network.main.name }
output "subnet_ids" { value = { for k, v in azurerm_subnet.subnets : k => v.id } }
output "nsg_ids" { value = { for k, v in azurerm_network_security_group.subnet_nsgs : k => v.id } }
