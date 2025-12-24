# =============================================================================
# Production Environment Configuration
# =============================================================================
# Full production settings
# - Premium plan for pre-warmed instances and VNET integration
# - Standard storage with GRS replication
# - Full Application Insights with 90-day retention
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "prod"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Runtime Configuration
runtime_stack   = "${{ values.runtimeStack }}"
runtime_version = "${{ values.runtimeVersion }}"

# Hosting Configuration
sku_tier             = "${{ values.skuTier }}"
storage_account_tier = "${{ values.storageAccountTier }}"

# Monitoring
enable_app_insights = ${{ values.enableAppInsights }}

# Application Settings
app_settings = {}

# CORS - Configure for production
cors_allowed_origins     = ["https://portal.azure.com"]
cors_support_credentials = false

# Tags
tags = {
  CostCenter  = "production"
  Criticality = "high"
}
