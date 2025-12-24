# =============================================================================
# Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development
# - Free tier
# - No custom domain
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "dev"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Static Web App Configuration
sku_tier  = "Free"
framework = "${{ values.framework }}"

# Preview Environments
enable_preview_environments = true
enable_config_file_changes  = true

# Custom Domain - Not available on Free tier
custom_domain = ""

# API Backend
api_backend_resource_id = ""

# Tags
tags = {
  CostCenter = "development"
}
