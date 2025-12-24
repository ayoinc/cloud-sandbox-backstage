# =============================================================================
# Azure Static Web App - Root Module
# =============================================================================

module "static_web" {
  source = "./modules/static-web"

  # Required variables
  name        = var.name
  environment = var.environment
  location    = var.location
  description = var.description
  owner       = var.owner

  # Static Web App Configuration
  sku_tier                    = var.sku_tier
  framework                   = var.framework
  enable_preview_environments = var.enable_preview_environments
  enable_config_file_changes  = var.enable_config_file_changes

  # Custom Domain
  custom_domain = var.custom_domain

  # API Backend
  api_backend_resource_id = var.api_backend_resource_id

  # Tags
  tags = var.tags
}
