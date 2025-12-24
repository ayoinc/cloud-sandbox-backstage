# =============================================================================
# Azure Functions - Root Module
# =============================================================================

module "functions" {
  source = "./modules/functions"

  # Required variables
  name        = var.name
  environment = var.environment
  location    = var.location
  description = var.description
  owner       = var.owner

  # Runtime Configuration
  runtime_stack   = var.runtime_stack
  runtime_version = var.runtime_version

  # Hosting Configuration
  sku_tier             = var.sku_tier
  storage_account_tier = var.storage_account_tier

  # Monitoring
  enable_app_insights = var.enable_app_insights

  # Application Settings
  app_settings = var.app_settings

  # CORS
  cors_allowed_origins     = var.cors_allowed_origins
  cors_support_credentials = var.cors_support_credentials

  # Tags
  tags = var.tags
}
