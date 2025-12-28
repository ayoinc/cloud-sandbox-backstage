# =============================================================================
# AZURE VIRTUAL NETWORK MODULE
# =============================================================================
# Creates Azure VNet with subnets, NSGs, and route tables
# Follows Azure CAF naming conventions and best practices
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

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_servers" {
  description = "Custom DNS servers"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }), null)
  }))
  default = {
    default = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection plan"
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "ID of existing DDoS protection plan"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Naming
  vnet_name = "vnet-${var.project}-${var.environment}-${var.location}"

  # Environment-specific sizing
  env_config = {
    dev = {
      flow_log_retention = 7
    }
    staging = {
      flow_log_retention = 14
    }
    prod = {
      flow_log_retention = 90
    }
  }

  config = lookup(local.env_config, var.environment, local.env_config["dev"])
}

# -----------------------------------------------------------------------------
# Virtual Network
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  dns_servers         = length(var.dns_servers) > 0 ? var.dns_servers : null

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection && var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                                          = "snet-${each.key}-${var.environment}"
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.main.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = each.value.service_endpoints
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Network Security Groups (one per subnet)
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "subnet_nsgs" {
  for_each = var.subnets

  name                = "nsg-${each.key}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnet_nsgs[each.key].id
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Virtual Network address space"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to address prefixes"
  value       = { for k, v in azurerm_subnet.subnets : k => v.address_prefixes }
}

output "nsg_ids" {
  description = "Map of NSG names to IDs"
  value       = { for k, v in azurerm_network_security_group.subnet_nsgs : k => v.id }
}

output "vnet_resource_group" {
  description = "Resource group containing the VNet"
  value       = var.resource_group_name
}
