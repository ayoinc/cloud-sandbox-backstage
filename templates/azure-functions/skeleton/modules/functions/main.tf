# =============================================================================
# Azure Functions Module
# =============================================================================
# This module creates an Azure Functions App with:
# - Resource Group
# - Storage Account
# - Service Plan (Consumption, Premium, or Dedicated)
# - Linux Function App
# - Application Insights with its Log Analytics workspace (optional)
# =============================================================================

locals {
  # Naming convention
  resource_group_name  = "rg-${var.name}-${var.environment}"
  function_app_name    = "func-${var.name}-${var.environment}"
  storage_account_name = lower(replace("st${var.name}${var.environment}", "-", ""))
  service_plan_name    = "asp-${var.name}-${var.environment}"
  app_insights_name    = "appi-${var.name}-${var.environment}"
  log_analytics_name   = "log-${var.name}-${var.environment}"

  # Truncate storage account name to 24 characters (Azure limit)
  storage_account_name_truncated = substr(local.storage_account_name, 0, min(24, length(local.storage_account_name)))

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Project      = var.name
      Environment  = var.environment
      ManagedBy    = "terraform"
      RuntimeStack = var.runtime_stack
    },
    var.owner != "" ? { Owner = var.owner } : {},
    var.description != "" ? { Description = substr(var.description, 0, 256) } : {},
  )

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

  selected_sku = lookup(local.sku_map, var.sku_tier, local.sku_map["Consumption"])

  # Premium storage offers only local or zone redundancy.
  storage_replication_type = var.environment == "prod" && var.storage_account_tier == "Standard" ? "GRS" : "LRS"

  # .NET functions run in the isolated worker model; the in-process model is retired.
  worker_runtime = var.runtime_stack == "dotnet" ? "dotnet-isolated" : var.runtime_stack
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
#trivy:ignore:AZU-0012 The Functions host reaches its storage over the public endpoint; Consumption plans have no VNet integration
resource "azurerm_storage_account" "main" {
  #checkov:skip=CKV_AZURE_59:The Functions host reaches its storage over the public endpoint; Consumption plans have no VNet integration
  #checkov:skip=CKV2_AZURE_33:A private endpoint needs VNet integration, which Consumption plans lack
  #checkov:skip=CKV2_AZURE_40:The Functions host connects to its storage with the account key
  #checkov:skip=CKV2_AZURE_1:Data is encrypted with platform-managed keys; a customer-managed key needs a Key Vault
  #checkov:skip=CKV_AZURE_206:Locally redundant outside production to save cost; production is geo-redundant
  name                     = local.storage_account_name_truncated
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = local.storage_replication_type
  min_tls_version          = "TLS1_2"

  # Enable secure transfer
  https_traffic_only_enabled = true

  # No anonymous access to blobs, and a second layer of encryption at rest
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  # The Functions host signs in with the account key; flag SAS tokens that are
  # valid for longer than a day
  shared_access_key_enabled = true

  sas_policy {
    expiration_period = "01.00:00:00"
    expiration_action = "Log"
  }

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

  # Request logging for the queues that back function triggers
  # (Premium accounts have no queue service)
  dynamic "queue_properties" {
    for_each = var.storage_account_tier == "Standard" ? [1] : []

    content {
      logging {
        delete                = true
        read                  = true
        write                 = true
        version               = "1.0"
        retention_policy_days = 7
      }
    }
  }

  tags = local.common_tags
}

# =============================================================================
# Service Plan
# =============================================================================
resource "azurerm_service_plan" "main" {
  #checkov:skip=CKV_AZURE_225:Zone redundancy needs at least three always-on instances; the Consumption and Basic SKUs do not offer it
  #checkov:skip=CKV_AZURE_212:The plan scales with demand; Consumption scales to zero by design
  name                = local.service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = local.selected_sku.name

  tags = local.common_tags
}

# =============================================================================
# Application Insights (workspace-based)
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  count = var.enable_app_insights ? 1 : 0

  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30

  tags = local.common_tags
}

resource "azurerm_application_insights" "main" {
  count = var.enable_app_insights ? 1 : 0

  name                = local.app_insights_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_id        = azurerm_log_analytics_workspace.main[0].id
  application_type    = "web"
  retention_in_days   = var.environment == "prod" ? 90 : 30

  tags = local.common_tags
}

# =============================================================================
# Linux Function App
# =============================================================================
resource "azurerm_linux_function_app" "main" {
  #checkov:skip=CKV_AZURE_221:HTTP-triggered functions are served from the public endpoint
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
      dotnet_version              = var.runtime_stack == "dotnet" ? var.runtime_version : null
      use_dotnet_isolated_runtime = var.runtime_stack == "dotnet" ? true : null
      node_version                = var.runtime_stack == "node" ? var.runtime_version : null
      python_version              = var.runtime_stack == "python" ? var.runtime_version : null
      java_version                = var.runtime_stack == "java" ? var.runtime_version : null
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
    "FUNCTIONS_WORKER_RUNTIME"       = local.worker_runtime
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
