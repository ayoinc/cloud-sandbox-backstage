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
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_user_assigned_identity" "this" {
  name                = var.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_role_assignment" "this" {
  for_each = { for idx, ra in var.role_assignments : idx => ra }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_federated_identity_credential" "this" {
  for_each = { for fic in var.federated_identity_credentials : fic.name => fic }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.this.id
  issuer              = each.value.issuer
  subject             = each.value.subject
  audience            = each.value.audiences
}
