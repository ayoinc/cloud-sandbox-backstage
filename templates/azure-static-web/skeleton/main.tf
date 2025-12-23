terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    # Configure your backend
  }
}

provider "azurerm" {
  features {}
}

locals {
  common_tags = {
    Project     = var.name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "${{ values.owner }}"
  }
  
  # Framework-specific build settings
  build_config = {
    react = {
      app_location         = "/"
      api_location         = "api"
      output_location      = "build"
    }
    vue = {
      app_location         = "/"
      api_location         = "api"
      output_location      = "dist"
    }
    angular = {
      app_location         = "/"
      api_location         = "api"
      output_location      = "dist/app"
    }
    nextjs = {
      app_location         = "/"
      api_location         = ""
      output_location      = ""
    }
    gatsby = {
      app_location         = "/"
      api_location         = "api"
      output_location      = "public"
    }
    hugo = {
      app_location         = "/"
      api_location         = "api"
      output_location      = "public"
    }
    static = {
      app_location         = "/"
      api_location         = ""
      output_location      = ""
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.name}-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

# Static Web App
resource "azurerm_static_web_app" "main" {
  name                = "swa-${var.name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_tier == "Free" ? "Free" : "Standard"
  
  tags = local.common_tags
}

# Custom Domain (for Standard tier)
resource "azurerm_static_web_app_custom_domain" "main" {
  count             = var.sku_tier == "Standard" && var.custom_domain != "" ? 1 : 0
  static_web_app_id = azurerm_static_web_app.main.id
  domain_name       = var.custom_domain
  validation_type   = "cname-delegation"
}

# Application Settings
resource "azurerm_static_web_app_function_app_registration" "api" {
  count                = var.api_backend_resource_id != "" ? 1 : 0
  static_web_app_id    = azurerm_static_web_app.main.id
  function_app_id      = var.api_backend_resource_id
}
