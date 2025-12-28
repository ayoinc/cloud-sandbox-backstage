# =============================================================================
# AZURE RESOURCE GROUP MODULE
# =============================================================================
# Creates Azure Resource Groups with proper naming, tagging, and lifecycle management
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

variable "name" {
  description = "Name of the resource group (will be prefixed with 'rg-')"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "Resource group name can only contain alphanumeric characters, hyphens, and underscores."
  }
}

variable "location" {
  description = "Azure region for the resource group"
  type        = string
}

variable "project" {
  description = "Project name for naming convention"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test, sandbox."
  }
}

variable "tags" {
  description = "Tags to apply to the resource group"
  type        = map(string)
  default     = {}
}

variable "enable_delete_lock" {
  description = "Enable delete lock on the resource group (recommended for prod)"
  type        = bool
  default     = false
}

variable "managed_by" {
  description = "Resource ID of the resource managing this resource group (optional)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Azure CAF naming convention: rg-<project>-<environment>-<region>
  resource_group_name = "rg-${var.project}-${var.environment}-${var.location}"

  # Merge default tags with provided tags
  default_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Module      = "azure/resources/core/resource-group"
  }

  merged_tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name       = local.resource_group_name
  location   = var.location
  managed_by = var.managed_by
  tags       = local.merged_tags
}

# -----------------------------------------------------------------------------
# Management Lock (optional)
# -----------------------------------------------------------------------------

resource "azurerm_management_lock" "delete_lock" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "delete-lock-${local.resource_group_name}"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"
  notes      = "This resource group is protected from deletion"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "tags" {
  description = "The tags applied to the resource group"
  value       = azurerm_resource_group.main.tags
}
