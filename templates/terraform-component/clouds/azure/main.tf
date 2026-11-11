locals {
  short_environment = {
    development = "dev"
    staging     = "stg"
    production  = "prod"
  }[var.environment]
}

# Suffix for names that must be unique across the whole cloud.
resource "random_id" "suffix" {
  byte_length = 4
}

module "naming" {
  source = "./modules/naming"

  convention     = var.naming_convention
  company        = var.company
  team           = var.business_unit
  project        = var.project_name
  environment    = local.short_environment
  unique_suffix  = random_id.suffix.hex
  resource_types = ["rg", "st", "stdr", "vnet", "kv", "cr", "log", "vm"]
}

module "tagging" {
  source = "./modules/tagging"

  component_name  = var.component_name
  component_type  = var.component_type
  project         = var.project_name
  environment     = var.environment
  business_unit   = var.business_unit
  cost_center     = var.cost_center
  application_id  = var.application_id
  owner           = var.owner
  additional_tags = var.additional_tags
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_container ? 1 : 0

  name     = module.naming.standard["rg"]
  location = var.region
  tags     = module.tagging.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_container ? 0 : 1

  name = var.resource_group_name

  lifecycle {
    precondition {
      condition     = var.resource_group_name != null
      error_message = "Set resource_group_name to an existing resource group, or set create_resource_container to true."
    }
  }
}

locals {
  resource_group_name = var.create_resource_container ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing[0].name
}
