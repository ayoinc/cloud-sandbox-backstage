mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/44444444-4444-4444-4444-444444444444"
      subscription_id = "44444444-4444-4444-4444-444444444444"
    }
  }
}

variables {
  project_name        = "demo-platform-services"
  environment         = "dev"
  location            = "eastus2"
  resource_group_name = "demo-dev-rg"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_log_analytics_workspace.main.name == "demo-platform-services-dev-law" && azurerm_log_analytics_workspace.main.retention_in_days == 30
    error_message = "The workspace must use the derived name and default retention."
  }

  assert {
    condition     = azurerm_application_insights.main[0].retention_in_days == 90 && azurerm_application_insights.main[0].ip_masking_enabled
    error_message = "Application Insights must be workspace-based with 90 day retention and IP masking."
  }

  assert {
    condition     = azurerm_monitor_action_group.main.short_name == "demoplatform" && length(azurerm_monitor_action_group.main.email_receiver) == 0
    error_message = "The action group short name must fit 12 characters and have no receivers by default."
  }

  assert {
    condition     = length(azurerm_monitor_metric_alert.high_cpu) == 0 && length(azurerm_monitor_metric_alert.high_memory) == 0 && length(azurerm_monitor_metric_alert.http_errors) == 0
    error_message = "Metric alerts need a monitored resource."
  }

  assert {
    condition     = azurerm_monitor_scheduled_query_rules_alert_v2.low_disk_space[0].criteria[0].threshold == 90 && azurerm_monitor_scheduled_query_rules_alert_v2.low_disk_space[0].skip_query_validation
    error_message = "The disk alert must fire above 90% usage."
  }

  assert {
    condition     = azurerm_monitor_activity_log_alert.service_health[0].location == "global" && azurerm_monitor_activity_log_alert.service_health[0].scopes == toset(["/subscriptions/44444444-4444-4444-4444-444444444444"])
    error_message = "The service health alert must be global and scoped to the subscription."
  }

  assert {
    condition     = azurerm_monitor_activity_log_alert.service_health[0].criteria[0].service_health[0].locations == null
    error_message = "An empty location list must mean all locations."
  }

  assert {
    condition     = length(azurerm_portal_dashboard.main) == 1 && length(azurerm_log_analytics_solution.container_insights) == 0 && length(azurerm_monitor_diagnostic_setting.target) == 0
    error_message = "Dashboard on, Container Insights and diagnostic setting off by default."
  }
}

run "alerts_and_receivers" {
  command = plan

  variables {
    alert_email                = "platform@example.com"
    additional_alert_emails    = ["oncall@example.com"]
    alert_webhook_urls         = ["https://hooks.example.com/azure-monitor"]
    alert_sms_receivers        = [{ name = "oncall", country_code = "1", phone_number = "5555550100" }]
    azure_app_push_receivers   = [{ name = "app", email_address = "oncall@example.com" }]
    monitored_resource_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Compute/virtualMachineScaleSets/demo-vmss"
    http_monitored_resource_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Web/sites/demo-func"
    memory_threshold           = 80
    service_health_locations   = ["East US 2"]
  }

  assert {
    condition     = length(azurerm_monitor_action_group.main.email_receiver) == 2 && length(azurerm_monitor_action_group.main.webhook_receiver) == 1 && length(azurerm_monitor_action_group.main.sms_receiver) == 1 && length(azurerm_monitor_action_group.main.azure_app_push_receiver) == 1
    error_message = "Every receiver must be added to the action group."
  }

  assert {
    condition     = azurerm_monitor_metric_alert.high_cpu[0].criteria[0].metric_namespace == "Microsoft.Compute/virtualMachineScaleSets" && azurerm_monitor_metric_alert.high_cpu[0].criteria[0].threshold == 80
    error_message = "The CPU alert must use the namespace of the monitored resource."
  }

  assert {
    condition     = azurerm_monitor_metric_alert.high_memory[0].criteria[0].operator == "LessThan" && azurerm_monitor_metric_alert.high_memory[0].criteria[0].threshold == 20
    error_message = "The memory alert must fire when available memory drops below 20%."
  }

  assert {
    condition     = azurerm_monitor_metric_alert.http_errors[0].criteria[0].metric_namespace == "Microsoft.Web/sites" && azurerm_monitor_metric_alert.http_errors[0].criteria[0].metric_name == "Http5xx"
    error_message = "The HTTP alert must watch Http5xx on the web resource."
  }

  assert {
    condition     = azurerm_monitor_activity_log_alert.service_health[0].criteria[0].service_health[0].locations == toset(["East US 2"])
    error_message = "Service health locations must be passed through."
  }
}

run "optional_features" {
  command = plan

  variables {
    enable_container_insights      = true
    diagnostic_setting_resource_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.KeyVault/vaults/kvdemo"
    diagnostic_log_categories      = ["AuditEvent"]
    diagnostic_log_category_groups = []
  }

  assert {
    condition     = azurerm_log_analytics_solution.container_insights[0].plan[0].product == "OMSGallery/ContainerInsights"
    error_message = "The Container Insights solution must be planned."
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.target[0].enabled_log) == 1 && length(azurerm_monitor_diagnostic_setting.target[0].enabled_metric) == 1
    error_message = "The diagnostic setting must collect the requested categories."
  }
}

run "everything_optional_disabled" {
  command = plan

  variables {
    enable_application_insights = false
    enable_disk_alert           = false
    enable_service_health_alert = false
    enable_dashboard            = false
  }

  assert {
    condition     = length(azurerm_application_insights.main) == 0 && length(azurerm_monitor_scheduled_query_rules_alert_v2.low_disk_space) == 0 && length(azurerm_monitor_activity_log_alert.service_health) == 0 && length(azurerm_portal_dashboard.main) == 0
    error_message = "Disabled features must not create resources."
  }

  assert {
    condition     = output.application_insights_id == null && output.dashboard_url == null
    error_message = "Outputs of disabled features must be null."
  }
}

run "rejects_window_shorter_than_frequency" {
  command = plan

  variables {
    alert_frequency   = "PT1H"
    alert_window_size = "PT15M"
  }

  expect_failures = [var.alert_window_size]
}

run "rejects_capacity_reservation_without_capacity" {
  command = plan

  variables {
    sku = "CapacityReservation"
  }

  expect_failures = [azurerm_log_analytics_workspace.main]
}
