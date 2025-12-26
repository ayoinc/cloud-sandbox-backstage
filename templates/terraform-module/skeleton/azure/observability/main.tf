# -----------------------------------------------------------------------------
# Azure Observability Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-observability"
    Environment = var.environment
    Project     = var.project
  })
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name_prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.log_retention_days

  daily_quota_gb                     = var.daily_quota_gb
  internet_ingestion_enabled         = var.internet_ingestion_enabled
  internet_query_enabled             = var.internet_query_enabled
  reservation_capacity_in_gb_per_day = var.sku == "CapacityReservation" ? var.reservation_capacity_in_gb_per_day : null

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Container Insights Solution (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_container_insights ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Application Insights (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${local.name_prefix}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = var.application_insights_type

  daily_data_cap_in_gb                  = var.application_insights_daily_cap_gb
  daily_data_cap_notifications_disabled = var.application_insights_disable_cap_notifications
  retention_in_days                     = var.log_retention_days
  sampling_percentage                   = var.application_insights_sampling_percentage
  disable_ip_masking                    = var.application_insights_disable_ip_masking

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Monitor Action Group for Alerts
# -----------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "main" {
  name                = "${local.name_prefix}-action-group"
  resource_group_name = var.resource_group_name
  short_name          = substr(replace("${var.project}${var.environment}", "-", ""), 0, 12)

  dynamic "email_receiver" {
    for_each = var.alert_email != null ? [var.alert_email] : []
    content {
      name                    = "primary-email"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "email_receiver" {
    for_each = var.additional_alert_emails
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "sms_receiver" {
    for_each = var.alert_sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.alert_webhook_urls
    content {
      name                    = "webhook-${webhook_receiver.key}"
      service_uri             = webhook_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "azure_app_push_receiver" {
    for_each = var.azure_app_push_receivers
    content {
      name          = azure_app_push_receiver.value.name
      email_address = azure_app_push_receiver.value.email_address
    }
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Metric Alerts
# -----------------------------------------------------------------------------

# High CPU Alert
resource "azurerm_monitor_metric_alert" "high_cpu" {
  count = var.enable_cpu_alert && var.monitored_resource_id != null ? 1 : 0

  name                = "${local.name_prefix}-high-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.monitored_resource_id]
  description         = "Alert triggered when CPU usage exceeds ${var.cpu_threshold}%"
  severity            = var.cpu_alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size
  enabled             = true

  criteria {
    metric_namespace = var.cpu_metric_namespace
    metric_name      = var.cpu_metric_name
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# High Memory Alert
resource "azurerm_monitor_metric_alert" "high_memory" {
  count = var.enable_memory_alert && var.monitored_resource_id != null ? 1 : 0

  name                = "${local.name_prefix}-high-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.monitored_resource_id]
  description         = "Alert triggered when memory usage exceeds ${var.memory_threshold}%"
  severity            = var.memory_alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size
  enabled             = true

  criteria {
    metric_namespace = var.memory_metric_namespace
    metric_name      = var.memory_metric_name
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.memory_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Low Disk Space Alert
resource "azurerm_monitor_metric_alert" "low_disk_space" {
  count = var.enable_disk_alert && var.monitored_resource_id != null ? 1 : 0

  name                = "${local.name_prefix}-low-disk-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.monitored_resource_id]
  description         = "Alert triggered when disk usage exceeds ${var.disk_threshold}%"
  severity            = var.disk_alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size
  enabled             = true

  criteria {
    metric_namespace = var.disk_metric_namespace
    metric_name      = var.disk_metric_name
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.disk_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# HTTP Errors Alert (for App Services, Functions, etc.)
resource "azurerm_monitor_metric_alert" "http_errors" {
  count = var.enable_http_errors_alert && var.monitored_resource_id != null ? 1 : 0

  name                = "${local.name_prefix}-http-errors-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.monitored_resource_id]
  description         = "Alert triggered when HTTP 5xx errors exceed ${var.http_errors_threshold}"
  severity            = var.http_errors_alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size
  enabled             = true

  criteria {
    metric_namespace = var.http_errors_metric_namespace
    metric_name      = var.http_errors_metric_name
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.http_errors_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Service Health Alert (Activity Log Alert)
# -----------------------------------------------------------------------------

resource "azurerm_monitor_activity_log_alert" "service_health" {
  count = var.enable_service_health_alert ? 1 : 0

  name                = "${local.name_prefix}-service-health-alert"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}"]
  description         = "Alert for Azure Service Health incidents"

  criteria {
    category = "ServiceHealth"

    service_health {
      events    = var.service_health_events
      locations = var.service_health_locations
      services  = var.service_health_services
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Data source for current subscription
data "azurerm_subscription" "current" {}

# -----------------------------------------------------------------------------
# Azure Dashboard
# -----------------------------------------------------------------------------

resource "azurerm_portal_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0

  name                = "${local.name_prefix}-dashboard"
  resource_group_name = var.resource_group_name
  location            = var.location
  dashboard_properties = templatefile("${path.module}/templates/dashboard.json.tpl", {
    subscription_id            = data.azurerm_subscription.current.subscription_id
    resource_group_name        = var.resource_group_name
    location                   = var.location
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    application_insights_id    = var.enable_application_insights ? azurerm_application_insights.main[0].id : ""
    project                    = var.project
    environment                = var.environment
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Diagnostic Settings Example
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "example" {
  count = var.diagnostic_setting_resource_id != null ? 1 : 0

  name                       = "${local.name_prefix}-diagnostic-setting"
  target_resource_id         = var.diagnostic_setting_resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = var.diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}
