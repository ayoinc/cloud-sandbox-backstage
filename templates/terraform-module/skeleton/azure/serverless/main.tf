# -----------------------------------------------------------------------------
# Azure Serverless Module - Main Resources
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

resource "random_id" "serverless" {
  byte_length = 4
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Function App, API Management, Service Bus and Event Grid names are global
  # DNS labels; the shortest limit among them is 50 characters.
  short_prefix = trimsuffix(substr(local.name_prefix, 0, 36), "-")
  suffix       = random_id.serverless.hex

  # Storage account names are global, 3-24 lowercase alphanumeric characters.
  storage_account_name = "${substr(replace("${var.project_name}${var.environment}", "-", ""), 0, 14)}fn${local.suffix}"

  is_consumption     = var.sku_name == "Y1"
  is_elastic_premium = startswith(var.sku_name, "EP")
  is_dedicated       = !local.is_consumption && !local.is_elastic_premium

  vnet_integrated = var.vnet_integration_subnet_id != null

  application_insights_connection_string = var.create_application_insights ? azurerm_application_insights.function[0].connection_string : var.application_insights_connection_string

  # Identity-based connection settings read by the Functions Service Bus extension.
  service_bus_app_settings = var.enable_service_bus ? {
    "ServiceBusConnection__fullyQualifiedNamespace" = "${azurerm_servicebus_namespace.main[0].name}.servicebus.windows.net"
    "ServiceBusConnection__credential"              = "managedidentity"
    "ServiceBusConnection__clientId"                = azurerm_user_assigned_identity.function.client_id
    "SERVICE_BUS_QUEUE_NAME"                        = azurerm_servicebus_queue.main[0].name
  } : {}

  event_grid_app_settings = var.enable_event_grid ? {
    "EVENT_GRID_TOPIC_ENDPOINT" = azurerm_eventgrid_topic.main[0].endpoint
  } : {}

  # Content and package traffic to the storage account stays inside the VNet.
  vnet_app_settings = local.vnet_integrated ? {
    "WEBSITE_CONTENTOVERVNET" = "1"
  } : {}
}

# -----------------------------------------------------------------------------
# User Assigned Managed Identity
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "function" {
  name                = "${local.name_prefix}-func-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# The function may read (not change) the resources of its own resource group.
resource "azurerm_role_assignment" "function_reader" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.function.principal_id
  principal_type       = "ServicePrincipal"
}

# -----------------------------------------------------------------------------
# Storage Account for Function App
# -----------------------------------------------------------------------------

# Consumption plans cannot join a VNet, so the function host reaches this account over the public endpoint (key-authenticated, TLS 1.2);
# the firewall is closed to everything but the function subnet as soon as vnet_integration_subnet_id is set.
# trivy:ignore:AVD-AZU-0012
resource "azurerm_storage_account" "function" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"

  min_tls_version                  = "TLS1_2"
  https_traffic_only_enabled       = true
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  dynamic "network_rules" {
    for_each = local.vnet_integrated ? [1] : []

    content {
      default_action             = "Deny"
      virtual_network_subnet_ids = [var.vnet_integration_subnet_id]
      bypass                     = ["AzureServices"]
    }
  }

  tags = var.tags
}

# Container for function deployment packages
resource "azurerm_storage_container" "deployments" {
  name                  = "function-deployments"
  storage_account_id    = azurerm_storage_account.function.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Application Insights
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "function" {
  count = var.create_application_insights ? 1 : 0

  name                = "${local.name_prefix}-func-insights"
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id
  retention_in_days   = var.application_insights_retention_days

  tags = var.tags
}

# -----------------------------------------------------------------------------
# App Service Plan (Consumption, Elastic Premium or Dedicated)
# -----------------------------------------------------------------------------

resource "azurerm_service_plan" "function" {
  name                = "${local.short_prefix}-func-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  maximum_elastic_worker_count = local.is_elastic_premium ? var.maximum_elastic_worker_count : null

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Linux Function App
# -----------------------------------------------------------------------------

resource "azurerm_linux_function_app" "main" {
  name                = "${local.short_prefix}-func-${local.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key
  service_plan_id            = azurerm_service_plan.function.id

  https_only              = true
  builtin_logging_enabled = false

  ftp_publish_basic_authentication_enabled = false

  virtual_network_subnet_id = var.vnet_integration_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function.id]
  }

  key_vault_reference_identity_id = azurerm_user_assigned_identity.function.id

  site_config {
    always_on                              = local.is_dedicated
    ftps_state                             = "Disabled"
    http2_enabled                          = true
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
    vnet_route_all_enabled                 = local.vnet_integrated
    application_insights_connection_string = local.application_insights_connection_string

    application_stack {
      python_version              = var.runtime_stack == "python" ? var.runtime_version : null
      node_version                = var.runtime_stack == "node" ? var.runtime_version : null
      java_version                = var.runtime_stack == "java" ? var.runtime_version : null
      dotnet_version              = var.runtime_stack == "dotnet" ? var.runtime_version : null
      use_dotnet_isolated_runtime = var.runtime_stack == "dotnet" ? true : null
    }

    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []

      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }

    # Health checks need instances that stay running.
    health_check_path                 = local.is_consumption ? null : var.health_check_path
    health_check_eviction_time_in_min = local.is_consumption || var.health_check_path == null ? null : 5
  }

  app_settings = merge(
    {
      "ENVIRONMENT"     = var.environment
      "PROJECT"         = var.project_name
      "AZURE_CLIENT_ID" = azurerm_user_assigned_identity.function.client_id
    },
    local.vnet_app_settings,
    local.service_bus_app_settings,
    local.event_grid_app_settings,
    var.app_settings
  )

  tags = var.tags

  lifecycle {
    # Deployments point the app at the package they publish.
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]

    precondition {
      condition     = !local.vnet_integrated || !local.is_consumption
      error_message = "The Consumption plan (Y1) does not support VNet integration: use an EP, B, S or P sku_name with vnet_integration_subnet_id."
    }
    precondition {
      condition     = var.create_application_insights || var.application_insights_connection_string != null
      error_message = "application_insights_connection_string is required when create_application_insights is false."
    }
    precondition {
      condition     = !var.cors_support_credentials || !contains(var.cors_allowed_origins, "*")
      error_message = "cors_support_credentials cannot be combined with the wildcard origin."
    }
  }
}

# -----------------------------------------------------------------------------
# API Management (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_api_management" "main" {
  count = var.enable_api_management ? 1 : 0

  name                = "${local.short_prefix}-apim-${local.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function.id]
  }

  dynamic "virtual_network_configuration" {
    for_each = var.apim_subnet_id != null ? [1] : []

    content {
      subnet_id = var.apim_subnet_id
    }
  }

  virtual_network_type = var.apim_subnet_id != null ? "External" : "None"

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.apim_publisher_email != null
      error_message = "apim_publisher_email is required when enable_api_management is true: API Management sends service notifications to it."
    }
    precondition {
      condition     = var.apim_subnet_id == null || can(regex("^(Developer|Premium)_", var.apim_sku_name))
      error_message = "apim_subnet_id needs a Developer or Premium apim_sku_name."
    }
  }
}

# The function host key lets API Management call key-protected functions.
data "azurerm_function_app_host_keys" "main" {
  count = var.enable_api_management ? 1 : 0

  name                = azurerm_linux_function_app.main.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_named_value" "function_key" {
  count = var.enable_api_management ? 1 : 0

  name                = "function-host-key"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main[0].name
  display_name        = "function-host-key"
  secret              = true
  value               = data.azurerm_function_app_host_keys.main[0].default_function_key
}

resource "azurerm_api_management_backend" "function" {
  count = var.enable_api_management ? 1 : 0

  name                = "${local.name_prefix}-func-backend"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main[0].name
  protocol            = "http"
  url                 = "https://${azurerm_linux_function_app.main.default_hostname}/api"
  resource_id         = "https://management.azure.com${azurerm_linux_function_app.main.id}"

  credentials {
    header = {
      # API Management resolves the named value when it calls the backend.
      "x-functions-key" = "{{${azurerm_api_management_named_value.function_key[0].name}}}"
    }
  }
}

resource "azurerm_api_management_api" "function" {
  count = var.enable_api_management ? 1 : 0

  name                  = "${local.name_prefix}-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.main[0].name
  revision              = "1"
  display_name          = "${var.project_name} ${var.environment} API"
  path                  = var.apim_api_path
  protocols             = ["https"]
  subscription_required = var.apim_subscription_required
}

# One catch-all operation per HTTP method forwards every path to the function app.
resource "azurerm_api_management_api_operation" "function" {
  for_each = var.enable_api_management ? toset(var.apim_http_methods) : toset([])

  operation_id        = "${lower(each.value)}-all"
  api_name            = azurerm_api_management_api.function[0].name
  api_management_name = azurerm_api_management.main[0].name
  resource_group_name = var.resource_group_name
  display_name        = "${each.value} any path"
  method              = each.value
  url_template        = "/*"
}

resource "azurerm_api_management_api_policy" "function" {
  count = var.enable_api_management ? 1 : 0

  api_name            = azurerm_api_management_api.function[0].name
  api_management_name = azurerm_api_management.main[0].name
  resource_group_name = var.resource_group_name

  xml_content = join("", [
    "<policies>",
    "<inbound><base /><set-backend-service backend-id=\"${azurerm_api_management_backend.function[0].name}\" /></inbound>",
    "<backend><base /></backend>",
    "<outbound><base /></outbound>",
    "<on-error><base /></on-error>",
    "</policies>",
  ])
}

# -----------------------------------------------------------------------------
# Service Bus Namespace and Queue (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_namespace" "main" {
  count = var.enable_service_bus ? 1 : 0

  name                = "${local.short_prefix}-sbns-${local.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.service_bus_sku

  capacity                     = var.service_bus_sku == "Premium" ? var.service_bus_capacity : null
  premium_messaging_partitions = var.service_bus_sku == "Premium" ? 1 : null

  # Clients authenticate with Microsoft Entra ID; shared access keys are off.
  local_auth_enabled  = false
  minimum_tls_version = "1.2"

  tags = var.tags
}

# Azure creates the dead-letter sub-queue of this queue automatically.
resource "azurerm_servicebus_queue" "main" {
  count = var.enable_service_bus ? 1 : 0

  name         = "${local.name_prefix}-queue"
  namespace_id = azurerm_servicebus_namespace.main[0].id

  max_delivery_count                   = var.service_bus_max_delivery_count
  lock_duration                        = var.service_bus_lock_duration
  max_size_in_megabytes                = var.service_bus_max_size_mb
  dead_lettering_on_message_expiration = true
  partitioning_enabled                 = var.service_bus_sku == "Standard" ? var.service_bus_enable_partitioning : false

  default_message_ttl = var.service_bus_message_ttl
}

resource "azurerm_role_assignment" "function_servicebus_receiver" {
  count = var.enable_service_bus ? 1 : 0

  scope                = azurerm_servicebus_namespace.main[0].id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.function.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "function_servicebus_sender" {
  count = var.enable_service_bus ? 1 : 0

  scope                = azurerm_servicebus_namespace.main[0].id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.function.principal_id
  principal_type       = "ServicePrincipal"
}

# -----------------------------------------------------------------------------
# Event Grid Topic (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_eventgrid_topic" "main" {
  count = var.enable_event_grid ? 1 : 0

  name                = "${local.short_prefix}-egt-${local.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  input_schema = "EventGridSchema"

  public_network_access_enabled = var.event_grid_public_access
  local_auth_enabled            = var.event_grid_local_auth_enabled

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function.id]
  }

  tags = var.tags
}

# The function publishes events to the topic with its managed identity.
resource "azurerm_role_assignment" "function_eventgrid_sender" {
  count = var.enable_event_grid ? 1 : 0

  scope                = azurerm_eventgrid_topic.main[0].id
  role_definition_name = "EventGrid Data Sender"
  principal_id         = azurerm_user_assigned_identity.function.principal_id
  principal_type       = "ServicePrincipal"
}

# Event Grid validates the endpoint when the subscription is created, so the
# function named event_grid_function_name must already be deployed to the app.
resource "azurerm_eventgrid_event_subscription" "function" {
  count = var.enable_event_grid && var.event_grid_create_subscription ? 1 : 0

  name  = "${local.name_prefix}-func-sub"
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
