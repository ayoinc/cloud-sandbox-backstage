# =============================================================================
# IDENTITY MODULE
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
variable "create_user_assigned_identity" { type = bool; default = true }

locals {
  identity_name = "id-${var.project}-${var.environment}-${var.location}"
}

resource "azurerm_user_assigned_identity" "main" {
  count               = var.create_user_assigned_identity ? 1 : 0
  name                = local.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

output "managed_identity_id" {
  value = var.create_user_assigned_identity ? azurerm_user_assigned_identity.main[0].id : null
}

output "managed_identity_principal_id" {
  value = var.create_user_assigned_identity ? azurerm_user_assigned_identity.main[0].principal_id : null
}

output "managed_identity_client_id" {
  value = var.create_user_assigned_identity ? azurerm_user_assigned_identity.main[0].client_id : null
}
