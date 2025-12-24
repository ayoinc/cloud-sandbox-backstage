# =============================================================================
# Production Environment Configuration
# =============================================================================
# Full production settings
# - Standard tier for custom domains and SLA
# - Custom domain enabled
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "prod"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Static Web App Configuration
sku_tier  = "Standard"
framework = "${{ values.framework }}"

# Preview Environments
enable_preview_environments = false  # Disable preview environments in prod
enable_config_file_changes  = false  # Lock down config changes in prod

# Custom Domain - Configure for production
custom_domain = ""  # Set your custom domain here

# API Backend
api_backend_resource_id = ""

# Tags
tags = {
  CostCenter  = "production"
  Criticality = "high"
}
