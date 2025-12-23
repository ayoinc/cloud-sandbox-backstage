# Azure Monitoring & Logging Module

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "this" {
  for_each                   = var.log_analytics_workspaces
  name                       = each.key
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku                        = each.value.sku
  retention_in_days          = each.value.retention_in_days
  daily_quota_gb             = each.value.daily_quota_gb
  internet_ingestion_enabled = each.value.internet_ingestion_enabled
  internet_query_enabled     = each.value.internet_query_enabled
  tags                       = var.tags
}

# Log Analytics Solutions
resource "azurerm_log_analytics_solution" "this" {
  for_each              = var.log_analytics_solutions
  solution_name         = each.value.solution_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this[each.value.workspace_key].id
  workspace_name        = azurerm_log_analytics_workspace.this[each.value.workspace_key].name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }
}

# Application Insights
resource "azurerm_application_insights" "this" {
  for_each                   = var.application_insights
  name                       = each.key
  location                   = var.location
  resource_group_name        = var.resource_group_name
  workspace_id               = each.value.workspace_key != null ? azurerm_log_analytics_workspace.this[each.value.workspace_key].id : each.value.workspace_id
  application_type           = each.value.application_type
  retention_in_days          = each.value.retention_in_days
  daily_data_cap_in_gb       = each.value.daily_data_cap_in_gb
  sampling_percentage        = each.value.sampling_percentage
  disable_ip_masking         = each.value.disable_ip_masking
  internet_ingestion_enabled = each.value.internet_ingestion_enabled
  internet_query_enabled     = each.value.internet_query_enabled
  tags                       = var.tags
}

# Azure Monitor Action Groups
resource "azurerm_monitor_action_group" "this" {
  for_each            = var.action_groups
  name                = each.key
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  enabled             = each.value.enabled

  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema
    }
  }

  dynamic "azure_app_push_receiver" {
    for_each = each.value.azure_app_push_receivers
    content {
      name          = azure_app_push_receiver.value.name
      email_address = azure_app_push_receiver.value.email_address
    }
  }

  tags = var.tags
}

# Azure Monitor Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                       = var.diagnostic_settings
  name                           = each.key
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = each.value.workspace_key != null ? azurerm_log_analytics_workspace.this[each.value.workspace_key].id : each.value.log_analytics_workspace_id
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
  eventhub_name                  = each.value.eventhub_name

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Azure Monitor Metric Alerts
resource "azurerm_monitor_metric_alert" "this" {
  for_each            = var.metric_alerts
  name                = each.key
  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity
  enabled             = each.value.enabled
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  auto_mitigate       = each.value.auto_mitigate

  dynamic "criteria" {
    for_each = each.value.criteria
    content {
      metric_namespace = criteria.value.metric_namespace
      metric_name      = criteria.value.metric_name
      aggregation      = criteria.value.aggregation
      operator         = criteria.value.operator
      threshold        = criteria.value.threshold
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_keys
    content {
      action_group_id = azurerm_monitor_action_group.this[action.value].id
    }
  }

  tags = var.tags
}

# Azure Monitor Activity Log Alerts
resource "azurerm_monitor_activity_log_alert" "this" {
  for_each            = var.activity_log_alerts
  name                = each.key
  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  enabled             = each.value.enabled

  criteria {
    category       = each.value.criteria.category
    operation_name = each.value.criteria.operation_name
    level          = each.value.criteria.level
    status         = each.value.criteria.status
  }

  dynamic "action" {
    for_each = each.value.action_group_keys
    content {
      action_group_id = azurerm_monitor_action_group.this[action.value].id
    }
  }

  tags = var.tags
}

# Azure Monitor Data Collection Rules
resource "azurerm_monitor_data_collection_rule" "this" {
  for_each            = var.data_collection_rules
  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = each.value.kind

  destinations {
    dynamic "log_analytics" {
      for_each = each.value.log_analytics_destinations
      content {
        workspace_resource_id = azurerm_log_analytics_workspace.this[log_analytics.value.workspace_key].id
        name                  = log_analytics.value.name
      }
    }
  }

  dynamic "data_flow" {
    for_each = each.value.data_flows
    content {
      streams      = data_flow.value.streams
      destinations = data_flow.value.destinations
    }
  }

  dynamic "data_sources" {
    for_each = each.value.data_sources != null ? [each.value.data_sources] : []
    content {
      dynamic "syslog" {
        for_each = data_sources.value.syslog != null ? data_sources.value.syslog : []
        content {
          facility_names = syslog.value.facility_names
          log_levels     = syslog.value.log_levels
          name           = syslog.value.name
          streams        = syslog.value.streams
        }
      }

      dynamic "performance_counter" {
        for_each = data_sources.value.performance_counters != null ? data_sources.value.performance_counters : []
        content {
          counter_specifiers            = performance_counter.value.counter_specifiers
          name                          = performance_counter.value.name
          sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
          streams                       = performance_counter.value.streams
        }
      }
    }
  }

  tags = var.tags
}

# Azure Monitor Private Link Scope
resource "azurerm_monitor_private_link_scope" "this" {
  for_each            = var.private_link_scopes
  name                = each.key
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_monitor_private_link_scoped_service" "log_analytics" {
  for_each            = var.private_link_scope_services
  name                = each.key
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.this[each.value.scope_key].name
  linked_resource_id  = each.value.workspace_key != null ? azurerm_log_analytics_workspace.this[each.value.workspace_key].id : each.value.linked_resource_id
}
