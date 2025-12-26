# -----------------------------------------------------------------------------
# Azure Serverless Module - Main Resources
# -----------------------------------------------------------------------------

# Data source for current subscription
data "azurerm_subscription" "current" {}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# User Assigned Managed Identity
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "function" {
  name                = "${var.project}-${var.environment}-func-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Role Assignment for Managed Identity (Reader on Resource Group)
resource "azurerm_role_assignment" "function_reader" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.function.principal_id
}

# -----------------------------------------------------------------------------
# Storage Account for Function App
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "function" {
  name                     = replace("${var.project}${var.environment}func", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  # Enable HTTPS only
  https_traffic_only_enabled = true

  # Blob properties for versioning and soft delete
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  # Network rules (optional VNet integration)
  dynamic "network_rules" {
    for_each = var.vnet_integration_subnet_id != null ? [1] : []
    content {
      default_action             = "Deny"
      virtual_network_subnet_ids = [var.vnet_integration_subnet_id]
      bypass                     = ["AzureServices"]
    }
  }

  tags = var.tags
}

# Storage container for function app deployments
resource "azurerm_storage_container" "deployments" {
  name                  = "function-deployments"
  storage_account_id    = azurerm_storage_account.function.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Application Insights
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "function" {
  count = var.application_insights_connection_string == null ? 1 : 0

  name                = "${var.project}-${var.environment}-func-insights"
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"
  retention_in_days   = var.application_insights_retention_days

  tags = var.tags
}

locals {
  application_insights_connection_string = var.application_insights_connection_string != null ? var.application_insights_connection_string : azurerm_application_insights.function[0].connection_string
  application_insights_key               = var.application_insights_connection_string != null ? null : azurerm_application_insights.function[0].instrumentation_key
}

# -----------------------------------------------------------------------------
# App Service Plan (Consumption or Premium)
# -----------------------------------------------------------------------------

resource "azurerm_service_plan" "function" {
  name                = "${var.project}-${var.environment}-func-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  # For Elastic Premium plans, configure maximum elastic worker count
  maximum_elastic_worker_count = var.sku_name != "Y1" ? var.maximum_elastic_worker_count : null

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Linux Function App
# -----------------------------------------------------------------------------

resource "azurerm_linux_function_app" "main" {
  name                = "${var.project}-${var.environment}-func"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key
  service_plan_id            = azurerm_service_plan.function.id

  # HTTPS only
  https_only = true

  # Enable built-in authentication (optional)
  builtin_logging_enabled = true

  # VNet integration (optional)
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  # Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function.id]
  }

  # Site configuration
  site_config {
    always_on                              = var.sku_name != "Y1" ? true : false
    ftps_state                             = "Disabled"
    http2_enabled                          = true
    minimum_tls_version                    = "1.2"
    application_insights_connection_string = local.application_insights_connection_string
    application_insights_key               = local.application_insights_key

    # Application stack
    application_stack {
      python_version = var.runtime_stack == "python" ? var.runtime_version : null
      node_version   = var.runtime_stack == "node" ? var.runtime_version : null
      java_version   = var.runtime_stack == "java" ? var.runtime_version : null
      dotnet_version = var.runtime_stack == "dotnet" ? var.runtime_version : null
    }

    # CORS configuration
    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }

    # Health check (for premium plans)
    health_check_path                 = var.sku_name != "Y1" ? var.health_check_path : null
    health_check_eviction_time_in_min = var.sku_name != "Y1" ? 5 : null
  }

  # App settings
  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME"       = var.runtime_stack
      "WEBSITE_RUN_FROM_PACKAGE"       = "1"
      "APPINSIGHTS_INSTRUMENTATIONKEY" = local.application_insights_key
      "ENVIRONMENT"                    = var.environment
      "PROJECT"                        = var.project
    },
    var.enable_service_bus ? {
      "ServiceBusConnection" = azurerm_servicebus_namespace.main[0].default_primary_connection_string
    } : {},
    var.app_settings
  )

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# -----------------------------------------------------------------------------
# API Management (Optional - Azure equivalent of API Gateway)
# -----------------------------------------------------------------------------

resource "azurerm_api_management" "main" {
  count = var.enable_api_management ? 1 : 0

  name                = "${var.project}-${var.environment}-apim"
  resource_group_name = var.resource_group_name
  location            = var.location
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function.id]
  }

  # Virtual network configuration (optional)
  dynamic "virtual_network_configuration" {
    for_each = var.apim_subnet_id != null ? [1] : []
    content {
      subnet_id = var.apim_subnet_id
    }
  }

  virtual_network_type = var.apim_subnet_id != null ? "External" : "None"

  tags = var.tags
}

# API Management API
resource "azurerm_api_management_api" "function" {
  count = var.enable_api_management ? 1 : 0

  name                  = "${var.project}-${var.environment}-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.main[0].name
  revision              = "1"
  display_name          = "${var.project} ${var.environment} API"
  path                  = var.apim_api_path
  protocols             = ["https"]
  subscription_required = var.apim_subscription_required

  service_url = "https://${azurerm_linux_function_app.main.default_hostname}/api"
}

# API Management Backend
resource "azurerm_api_management_backend" "function" {
  count = var.enable_api_management ? 1 : 0

  name                = "${var.project}-${var.environment}-func-backend"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main[0].name
  protocol            = "http"
  url                 = "https://${azurerm_linux_function_app.main.default_hostname}/api"

  credentials {
    header = {
      "x-functions-key" = azurerm_linux_function_app.main.id
    }
  }
}

# -----------------------------------------------------------------------------
# Service Bus Namespace and Queue (Optional - Azure equivalent of SQS)
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_namespace" "main" {
  count = var.enable_service_bus ? 1 : 0

  name                = "${var.project}-${var.environment}-sbns"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.service_bus_sku

  # Premium tier features
  capacity = var.service_bus_sku == "Premium" ? var.service_bus_capacity : null

  # Local auth disabled for enhanced security (use managed identity)
  local_auth_enabled = false

  tags = var.tags
}

# Service Bus Queue
resource "azurerm_servicebus_queue" "main" {
  count = var.enable_service_bus ? 1 : 0

  name         = "${var.project}-${var.environment}-queue"
  namespace_id = azurerm_servicebus_namespace.main[0].id

  # Queue settings
  max_delivery_count                   = var.service_bus_max_delivery_count
  lock_duration                        = var.service_bus_lock_duration
  max_size_in_megabytes                = var.service_bus_max_size_mb
  dead_lettering_on_message_expiration = true
  partitioning_enabled                 = var.service_bus_sku != "Premium" ? var.service_bus_enable_partitioning : false

  # Message TTL
  default_message_ttl = var.service_bus_message_ttl
}

# Dead Letter Queue is automatically created by Azure Service Bus
# Access it via the main queue's dead letter sub-queue

# Role assignment for Function App to access Service Bus
resource "azurerm_role_assignment" "function_servicebus" {
  count = var.enable_service_bus ? 1 : 0

  scope                = azurerm_servicebus_namespace.main[0].id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.function.principal_id
}

# -----------------------------------------------------------------------------
# Event Grid Topic (Optional - Azure equivalent of EventBridge)
# -----------------------------------------------------------------------------

resource "azurerm_eventgrid_topic" "main" {
  count = var.enable_event_grid ? 1 : 0

  name                = "${var.project}-${var.environment}-egt"
  resource_group_name = var.resource_group_name
  location            = var.location

  input_schema = "EventGridSchema"

  # Public network access
  public_network_access_enabled = var.event_grid_public_access

  # Managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function.id]
  }

  tags = var.tags
}

# Event Grid Subscription to Function App
resource "azurerm_eventgrid_event_subscription" "function" {
  count = var.enable_event_grid ? 1 : 0

  name  = "${var.project}-${var.environment}-func-sub"
  scope = azurerm_eventgrid_topic.main[0].id

  azure_function_endpoint {
    function_id                       = "${azurerm_linux_function_app.main.id}/functions/${var.event_grid_function_name}"
    max_events_per_batch              = var.event_grid_max_events_per_batch
    preferred_batch_size_in_kilobytes = var.event_grid_preferred_batch_size_kb
  }

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }
}

# Role assignment for Event Grid to invoke Function
resource "azurerm_role_assignment" "eventgrid_function" {
  count = var.enable_event_grid ? 1 : 0

  scope                = azurerm_linux_function_app.main.id
  role_definition_name = "Website Contributor"
  principal_id         = azurerm_user_assigned_identity.function.principal_id
}
