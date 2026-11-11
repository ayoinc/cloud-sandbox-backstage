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
  resource_types = ["rg", "s3", "s3dr", "s3rep", "vpc", "kms", "ecr", "vm", "vmstop"]
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

# AWS has no container that resources are created in; a resource group
# collects the resources of this component by tag instead.
resource "aws_resourcegroups_group" "this" {
  count = var.create_resource_container ? 1 : 0

  name        = module.naming.standard["rg"]
  description = "Resources of the ${var.component_name} component"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        { Key = "Component", Values = [var.component_name] },
        { Key = "Environment", Values = [var.environment] },
      ]
    })
  }
}
