# =============================================================================
# Staging Environment Configuration
# =============================================================================
# Production-like settings for testing
# - Standard tier for custom domains
# - Preview environments enabled
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "staging"
location    = "${{ values.location }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# Static Web App Configuration
sku_tier  = "${{ values.skuTier if values.envName == 'staging' else 'Standard' }}"
framework = "${{ values.framework }}"

# Preview Environments
enable_preview_environments = true
enable_config_file_changes  = true

# Custom Domain - Optional for staging
custom_domain = ""

# API Backend
api_backend_resource_id = ""

# Tags
tags = {
  CostCenter = "staging"
  Testing    = "true"
}
