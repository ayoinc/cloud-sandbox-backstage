data "azurerm_client_config" "current" {}

locals {
  production = var.environment == "production"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Names that allow letters and digits only are built from the prefix
  # without its hyphens.
  compact_prefix = replace(var.name_prefix, "-", "")
  suffix         = random_id.suffix.hex

  zonal = length(var.availability_zones) > 1

  # Features that only apply outside production when costs are optimised.
  economy = var.enable_cost_optimization && !local.production

  registry_enabled  = contains(["container-platform", "ml-platform", "serverless-platform"], var.infrastructure_type)
  data_lake_enabled = contains(["data-platform", "ml-platform"], var.infrastructure_type)
  dns_zone_enabled  = var.infrastructure_type == "networking-foundation"

  # Azure Resource Manager template envelope shared by the deployments that
  # reach resources the provider can only manage through a data plane.
  arm_template_schema = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
}

# Globally unique names (storage accounts, vaults, database servers, the
# registry) end in this suffix.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-rg"
  location = var.region

  tags = local.tags
}
