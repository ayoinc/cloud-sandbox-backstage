# =============================================================================
# AZURE CONTAINER REGISTRY (ACR) MODULE
# =============================================================================
# Creates Azure Container Registry with geo-replication and security features
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

variable "sku" {
  description = "SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Enable admin user"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy (Premium SKU only)"
  type        = bool
  default     = false
}

variable "georeplications" {
  description = "Geo-replication locations (Premium SKU only)"
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool, false)
  }))
  default = []
}

variable "retention_policy_days" {
  description = "Days to retain untagged manifests"
  type        = number
  default     = 7
}

variable "trust_policy_enabled" {
  description = "Enable content trust (Premium SKU only)"
  type        = bool
  default     = false
}

variable "network_rule_set" {
  description = "Network rule set (Premium SKU only)"
  type = object({
    default_action = optional(string, "Deny")
    ip_rules       = optional(list(string), [])
    virtual_network = optional(list(object({
      action    = string
      subnet_id = string
    })), [])
  })
  default = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
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
  # ACR names must be 5-50 chars, alphanumeric only, globally unique
  acr_name = lower(replace("acr${var.project}${var.environment}${substr(md5("${var.project}-${var.environment}"), 0, 8)}", "/[^a-z0-9]/", ""))
}

# -----------------------------------------------------------------------------
# Container Registry
# -----------------------------------------------------------------------------

resource "azurerm_container_registry" "main" {
  name                          = substr(local.acr_name, 0, 50)
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.sku == "Premium" ? var.zone_redundancy_enabled : false

  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
    }
  }

  dynamic "retention_policy" {
    for_each = var.sku == "Premium" ? [1] : []
    content {
      days    = var.retention_policy_days
      enabled = true
    }
  }

  dynamic "trust_policy" {
    for_each = var.sku == "Premium" && var.trust_policy_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" && var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }

      dynamic "virtual_network" {
        for_each = network_rule_set.value.virtual_network
        content {
          action    = virtual_network.value.action
          subnet_id = virtual_network.value.subnet_id
        }
      }
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Private Endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "acr" {
  count = var.enable_private_endpoint && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${azurerm_container_registry.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_container_registry.main.name}"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "acr_id" {
  description = "Container Registry ID"
  value       = azurerm_container_registry.main.id
}

output "acr_name" {
  description = "Container Registry name"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  description = "Container Registry admin username"
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_username : null
  sensitive   = true
}

output "acr_admin_password" {
  description = "Container Registry admin password"
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_password : null
  sensitive   = true
}
