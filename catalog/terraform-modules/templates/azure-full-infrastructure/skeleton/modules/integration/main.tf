# =============================================================================
# INTEGRATION MODULE
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
variable "enable_service_bus" { type = bool; default = true }
variable "service_bus_sku" { type = string; default = "Standard" }
variable "enable_event_grid" { type = bool; default = true }

locals {
  service_bus_name = "sb-${var.project}-${var.environment}-${var.location}"
}

resource "azurerm_servicebus_namespace" "main" {
  count               = var.enable_service_bus ? 1 : 0
  name                = local.service_bus_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.service_bus_sku
  tags                = var.tags
}

output "service_bus_namespace_id" {
  value = var.enable_service_bus ? azurerm_servicebus_namespace.main[0].id : null
}

output "service_bus_connection_string" {
  value     = var.enable_service_bus ? azurerm_servicebus_namespace.main[0].default_primary_connection_string : null
  sensitive = true
}
