# =============================================================================
# Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development
# - Consumption plan (pay-per-use)
# - Standard storage
# - Application Insights enabled
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "dev"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Runtime Configuration
runtime_stack   = "${{ values.runtimeStack }}"
runtime_version = "${{ values.runtimeVersion }}"

# Hosting Configuration
sku_tier             = "Consumption"
storage_account_tier = "Standard"

# Monitoring
enable_app_insights = true

# Application Settings
app_settings = {}

# CORS
cors_allowed_origins     = ["https://portal.azure.com"]
cors_support_credentials = false

# Tags
tags = {
  CostCenter = "development"
}
