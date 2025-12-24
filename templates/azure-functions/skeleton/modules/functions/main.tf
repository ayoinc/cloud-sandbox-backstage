# =============================================================================
# Azure Functions Module
# =============================================================================
# This module creates an Azure Functions App with:
# - Resource Group
# - Storage Account
# - Service Plan (Consumption, Premium, or Dedicated)
# - Linux Function App
# - Application Insights (optional)
# =============================================================================

locals {
  # Naming convention
  resource_group_name  = "rg-${var.name}-${var.environment}"
  function_app_name    = "func-${var.name}-${var.environment}"
  storage_account_name = lower(replace("st${var.name}${var.environment}", "-", ""))
  service_plan_name    = "asp-${var.name}-${var.environment}"
  app_insights_name    = "appi-${var.name}-${var.environment}"

  # Truncate storage account name to 24 characters (Azure limit)
  storage_account_name_truncated = substr(local.storage_account_name, 0, min(24, length(local.storage_account_name)))

  # Common tags
  common_tags = merge(var.tags, {
    Project      = var.name
    Environment  = var.environment
    ManagedBy    = "terraform"
    RuntimeStack = var.runtime_stack
  })

  # SKU mapping for service plans
  sku_map = {
    Consumption = {
      name = "Y1"
      tier = "Dynamic"
    }
    Premium = {
      name = "EP1"
      tier = "ElasticPremium"
    }
    Dedicated = {
      name = "B1"
      tier = "Basic"
    }
  }

  # Runtime configuration mapping
  runtime_config = {
    dotnet = {
      stack         = "dotnet"
      version       = var.runtime_version
      start_command = ""
    }
    node = {
      stack         = "node"
      version       = var.runtime_version
      start_command = ""
    }
    python = {
      stack         = "python"
      version       = var.runtime_version
      start_command = ""
    }
    java = {
      stack         = "java"
      version       = var.runtime_version
      start_command = ""
    }
  }

  selected_sku     = lookup(local.sku_map, var.sku_tier, local.sku_map["Consumption"])
  selected_runtime = lookup(local.runtime_config, var.runtime_stack, local.runtime_config["node"])
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
# Storage Account
# =============================================================================
resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name_truncated
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  min_tls_version          = "TLS1_2"

  # Enable secure transfer
  https_traffic_only_enabled = true

  # Blob properties for function triggers
  blob_properties {
    versioning_enabled = var.environment == "prod" ? true : false

    delete_retention_policy {
      days = var.environment == "prod" ? 30 : 7
    }

    container_delete_retention_policy {
      days = var.environment == "prod" ? 30 : 7
    }
  }

  tags = local.common_tags
}

# =============================================================================
# Service Plan
# =============================================================================
resource "azurerm_service_plan" "main" {
  name                = local.service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = local.selected_sku.name

  tags = local.common_tags
}

# =============================================================================
# Application Insights
# =============================================================================
resource "azurerm_application_insights" "main" {
  count = var.enable_app_insights ? 1 : 0

  name                = local.app_insights_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"
  retention_in_days   = var.environment == "prod" ? 90 : 30

  tags = local.common_tags
}

# =============================================================================
# Linux Function App
# =============================================================================
resource "azurerm_linux_function_app" "main" {
  name                = local.function_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  service_plan_id            = azurerm_service_plan.main.id

  # HTTPS only
  https_only = true

  # Function App version
  functions_extension_version = "~4"

  site_config {
    # Runtime configuration
    application_stack {
      dotnet_version = var.runtime_stack == "dotnet" ? var.runtime_version : null
      node_version   = var.runtime_stack == "node" ? var.runtime_version : null
      python_version = var.runtime_stack == "python" ? var.runtime_version : null
      java_version   = var.runtime_stack == "java" ? var.runtime_version : null
    }

    # Always on for Premium and Dedicated
    always_on = var.sku_tier != "Consumption"

    # Minimum TLS version
    minimum_tls_version = "1.2"

    # CORS configuration
    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = var.cors_support_credentials
    }

    # Application Insights
    application_insights_connection_string = var.enable_app_insights ? azurerm_application_insights.main[0].connection_string : null
    application_insights_key               = var.enable_app_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  }

  app_settings = merge(var.app_settings, {
    "FUNCTIONS_WORKER_RUNTIME"       = var.runtime_stack
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  })

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }

  tags = local.common_tags
}
