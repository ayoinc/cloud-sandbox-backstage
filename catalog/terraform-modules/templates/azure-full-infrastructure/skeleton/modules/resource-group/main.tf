# =============================================================================
# RESOURCE GROUP MODULE
# =============================================================================
# Creates Azure Resource Groups with proper naming and lifecycle management
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

variable "name" {
  description = "Name suffix for the resource group"
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
  description = "Environment (dev, stg, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

variable "enable_delete_lock" {
  description = "Enable delete lock"
  type        = bool
  default     = false
}

variable "managed_by" {
  description = "Resource ID of managing resource"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  resource_group_name = "rg-${var.name}-${var.environment}-${var.location}"
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name       = local.resource_group_name
  location   = var.location
  managed_by = var.managed_by
  tags       = var.tags
}

resource "azurerm_management_lock" "delete_lock" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "delete-lock"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"
  notes      = "Protected from deletion"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.main.id
}

output "name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Resource group location"
  value       = azurerm_resource_group.main.location
}
