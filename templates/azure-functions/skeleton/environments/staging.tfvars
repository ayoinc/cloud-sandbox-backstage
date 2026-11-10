# =============================================================================
# Staging Environment Configuration
# =============================================================================
# Production-like settings for testing
# - Premium plan for pre-warmed instances
# - Standard storage with GRS
# - Application Insights enabled
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "staging"
location    = "${{ values.location }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# Runtime Configuration
runtime_stack   = "${{ values.runtimeStack }}"
runtime_version = "${{ values.runtimeVersion }}"

{% set fromForm = values.envName == 'staging' -%}
# Hosting Configuration{% if fromForm %} (from the template form){% endif %}
sku_tier             = "${{ values.skuTier if fromForm else 'Premium' }}"
storage_account_tier = "${{ values.storageAccountTier if fromForm else 'Standard' }}"

# Monitoring
enable_app_insights = ${{ (values.enableAppInsights | dump) if fromForm else 'true' }}

# Application Settings
app_settings = {}

# CORS
cors_allowed_origins     = ["https://portal.azure.com"]
cors_support_credentials = false

# Tags
tags = {
  CostCenter = "staging"
  Testing    = "true"
}
