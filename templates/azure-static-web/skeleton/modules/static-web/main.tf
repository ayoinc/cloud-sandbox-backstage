# =============================================================================
# Azure Static Web App Module
# =============================================================================
# This module creates an Azure Static Web App with:
# - Resource Group
# - Static Web App
# - Custom Domain (optional)
# - API Backend Registration (optional)
# =============================================================================

locals {
  # Naming convention
  resource_group_name = "rg-${var.name}-${var.environment}"
  static_web_app_name = "swa-${var.name}-${var.environment}"

  # Common tags
  common_tags = merge(var.tags, {
    Project     = var.name
    Environment = var.environment
    ManagedBy   = "terraform"
    Framework   = var.framework
  })

  # Framework-specific build settings
  build_config = {
    react = {
      app_location    = "/"
      api_location    = "api"
      output_location = "build"
    }
    vue = {
      app_location    = "/"
      api_location    = "api"
      output_location = "dist"
    }
    angular = {
      app_location    = "/"
      api_location    = "api"
      output_location = "dist/app"
    }
    nextjs = {
      app_location    = "/"
      api_location    = ""
      output_location = ""
    }
    gatsby = {
      app_location    = "/"
      api_location    = "api"
      output_location = "public"
    }
    hugo = {
      app_location    = "/"
      api_location    = "api"
      output_location = "public"
    }
    static = {
      app_location    = "/"
      api_location    = ""
      output_location = ""
    }
  }

  # Get build config for selected framework
  selected_build_config = lookup(local.build_config, var.framework, local.build_config["static"])
}

# =============================================================================
# Resource Group
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# =============================================================================
# Static Web App
# =============================================================================
resource "azurerm_static_web_app" "main" {
  name                = local.static_web_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_tier == "Free" ? "Free" : "Standard"

  # Preview environments configuration
  preview_environments_enabled = var.enable_preview_environments

  # Configuration file handling
  configuration_file_changes_enabled = var.enable_config_file_changes

  tags = local.common_tags
}

# =============================================================================
# Custom Domain (for Standard tier)
# =============================================================================
resource "azurerm_static_web_app_custom_domain" "main" {
  count = var.sku_tier == "Standard" && var.custom_domain != "" ? 1 : 0

  static_web_app_id = azurerm_static_web_app.main.id
  domain_name       = var.custom_domain
  validation_type   = "cname-delegation"
}

# =============================================================================
# API Backend Registration
# =============================================================================
resource "azurerm_static_web_app_function_app_registration" "api" {
  count = var.api_backend_resource_id != "" ? 1 : 0

  static_web_app_id = azurerm_static_web_app.main.id
  function_app_id   = var.api_backend_resource_id
}
