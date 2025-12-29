terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

locals {
  default_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_service_plan" "this" {
  name                = "${var.function_app_name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = local.tags
}

resource "azurerm_linux_function_app" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  https_only = var.https_only

  virtual_network_subnet_id = var.vnet_integration_subnet_id

  site_config {
    application_stack {
      node_version            = var.runtime_stack == "node" ? var.runtime_version : null
      python_version          = var.runtime_stack == "python" ? var.runtime_version : null
      dotnet_version          = var.runtime_stack == "dotnet" ? var.runtime_version : null
      java_version            = var.runtime_stack == "java" ? var.runtime_version : null
      powershell_core_version = var.runtime_stack == "powershell" ? var.runtime_version : null
    }

    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins = var.cors_allowed_origins
      }
    }
  }

  app_settings = merge(
    var.app_settings,
    var.application_insights_connection_string != null ? {
      APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection_string
    } : {}
  )

  dynamic "identity" {
    for_each = var.enable_system_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = local.tags
}

resource "azurerm_windows_function_app" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  https_only = var.https_only

  virtual_network_subnet_id = var.vnet_integration_subnet_id

  site_config {
    application_stack {
      node_version            = var.runtime_stack == "node" ? "~${var.runtime_version}" : null
      dotnet_version          = var.runtime_stack == "dotnet" ? var.runtime_version : null
      java_version            = var.runtime_stack == "java" ? var.runtime_version : null
      powershell_core_version = var.runtime_stack == "powershell" ? var.runtime_version : null
    }

    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins = var.cors_allowed_origins
      }
    }
  }

  app_settings = merge(
    var.app_settings,
    var.application_insights_connection_string != null ? {
      APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection_string
    } : {}
  )

  dynamic "identity" {
    for_each = var.enable_system_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = local.tags
}
