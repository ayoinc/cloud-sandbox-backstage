mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/44444444-4444-4444-4444-444444444444"
      subscription_id = "44444444-4444-4444-4444-444444444444"
    }
  }
}

mock_provider "random" {}

variables {
  project_name        = "demo-platform-services"
  environment         = "dev"
  location            = "eastus2"
  resource_group_name = "demo-dev-rg"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_service_plan.function.sku_name == "Y1" && azurerm_service_plan.function.os_type == "Linux"
    error_message = "The default plan must be Linux Consumption."
  }

  assert {
    condition     = azurerm_linux_function_app.main.https_only && azurerm_linux_function_app.main.site_config[0].minimum_tls_version == "1.2" && azurerm_linux_function_app.main.site_config[0].ftps_state == "Disabled"
    error_message = "The function app must be HTTPS-only with TLS 1.2 and FTPS disabled."
  }

  assert {
    condition     = azurerm_linux_function_app.main.site_config[0].application_stack[0].python_version == "3.12"
    error_message = "The default runtime must be Python 3.12."
  }

  assert {
    condition     = azurerm_linux_function_app.main.site_config[0].always_on == false && azurerm_linux_function_app.main.site_config[0].health_check_path == null
    error_message = "Consumption plans have no always-on or health check."
  }

  assert {
    condition     = azurerm_storage_account.function.min_tls_version == "TLS1_2" && azurerm_storage_account.function.allow_nested_items_to_be_public == false && length(azurerm_storage_account.function.network_rules) == 0
    error_message = "Storage must be TLS-only without anonymous access."
  }

  assert {
    condition     = azurerm_role_assignment.function_reader.scope == "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg"
    error_message = "The identity must only read its own resource group."
  }

  assert {
    condition     = length(azurerm_application_insights.function) == 1
    error_message = "Application Insights is created by default."
  }

  assert {
    condition     = length(azurerm_api_management.main) == 0 && length(azurerm_servicebus_namespace.main) == 0 && length(azurerm_eventgrid_topic.main) == 0
    error_message = "API Management, Service Bus and Event Grid are off by default."
  }
}

run "premium_plan_with_vnet_and_existing_insights" {
  command = plan

  variables {
    sku_name                               = "EP1"
    vnet_integration_subnet_id             = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/functions"
    create_application_insights            = false
    application_insights_connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://eastus2-0.in.applicationinsights.azure.com/"
    runtime_stack                          = "dotnet"
    runtime_version                        = "8.0"
    cors_allowed_origins                   = ["https://app.example.com"]
  }

  assert {
    condition     = azurerm_service_plan.function.maximum_elastic_worker_count == 20
    error_message = "Elastic Premium plans must set the worker limit."
  }

  assert {
    condition     = azurerm_storage_account.function.network_rules[0].default_action == "Deny" && azurerm_storage_account.function.network_rules[0].virtual_network_subnet_ids == toset([var.vnet_integration_subnet_id])
    error_message = "With VNet integration the storage account must admit only the function subnet."
  }

  assert {
    condition     = azurerm_linux_function_app.main.virtual_network_subnet_id == var.vnet_integration_subnet_id && azurerm_linux_function_app.main.site_config[0].vnet_route_all_enabled
    error_message = "The function app must route through the subnet."
  }

  assert {
    condition     = azurerm_linux_function_app.main.site_config[0].health_check_path == "/api/health" && azurerm_linux_function_app.main.site_config[0].always_on == false
    error_message = "Elastic Premium plans get a health check but not always-on."
  }

  assert {
    condition     = azurerm_linux_function_app.main.site_config[0].application_stack[0].dotnet_version == "8.0" && azurerm_linux_function_app.main.site_config[0].application_stack[0].use_dotnet_isolated_runtime
    error_message = ".NET must run in the isolated worker."
  }

  assert {
    condition     = length(azurerm_application_insights.function) == 0 && length(azurerm_linux_function_app.main.site_config[0].cors) == 1
    error_message = "No Application Insights is created and CORS is configured."
  }
}

run "api_management_service_bus_and_event_grid" {
  command = plan

  variables {
    enable_api_management          = true
    apim_publisher_email           = "platform@example.com"
    apim_http_methods              = ["GET", "POST"]
    enable_service_bus             = true
    enable_event_grid              = true
    event_grid_create_subscription = true
  }

  assert {
    condition     = azurerm_api_management.main[0].sku_name == "Consumption_0" && azurerm_api_management.main[0].publisher_email == "platform@example.com"
    error_message = "API Management must be created on the Consumption tier."
  }

  assert {
    condition     = sort(keys(azurerm_api_management_api_operation.function)) == tolist(["GET", "POST"]) && azurerm_api_management_api_operation.function["GET"].url_template == "/*"
    error_message = "One catch-all operation per method is expected."
  }

  assert {
    condition     = azurerm_api_management_named_value.function_key[0].secret && azurerm_api_management_api.function[0].protocols == toset(["https"])
    error_message = "The function key must be a secret named value and the API HTTPS-only."
  }

  assert {
    condition     = azurerm_servicebus_namespace.main[0].local_auth_enabled == false && azurerm_servicebus_namespace.main[0].minimum_tls_version == "1.2"
    error_message = "Service Bus must use Entra ID authentication and TLS 1.2."
  }

  assert {
    condition     = azurerm_servicebus_queue.main[0].name == "demo-platform-services-dev-queue" && azurerm_servicebus_queue.main[0].dead_lettering_on_message_expiration
    error_message = "The queue must dead-letter expired messages."
  }

  assert {
    condition     = azurerm_role_assignment.function_servicebus_receiver[0].role_definition_name == "Azure Service Bus Data Receiver" && azurerm_role_assignment.function_servicebus_sender[0].role_definition_name == "Azure Service Bus Data Sender"
    error_message = "The function identity must get data-plane roles only."
  }

  assert {
    condition     = azurerm_linux_function_app.main.app_settings["ServiceBusConnection__credential"] == "managedidentity"
    error_message = "The function must connect to Service Bus with its managed identity."
  }

  assert {
    condition     = azurerm_eventgrid_topic.main[0].local_auth_enabled == false && length(azurerm_eventgrid_event_subscription.function) == 1
    error_message = "The topic must use Entra ID authentication and the subscription be created."
  }
}

run "event_grid_without_subscription" {
  command = plan

  variables {
    enable_event_grid = true
  }

  assert {
    condition     = length(azurerm_eventgrid_topic.main) == 1 && length(azurerm_eventgrid_event_subscription.function) == 0 && length(azurerm_role_assignment.function_eventgrid_sender) == 1
    error_message = "The topic is created without a subscription until the function is deployed."
  }
}

run "rejects_vnet_integration_on_consumption" {
  command = plan

  variables {
    vnet_integration_subnet_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/functions"
  }

  expect_failures = [azurerm_linux_function_app.main]
}

run "rejects_api_management_without_publisher_email" {
  command = plan

  variables {
    enable_api_management = true
  }

  expect_failures = [azurerm_api_management.main]
}

run "rejects_missing_insights_connection_string" {
  command = plan

  variables {
    create_application_insights = false
  }

  expect_failures = [azurerm_linux_function_app.main]
}
