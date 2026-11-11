# -----------------------------------------------------------------------------
# Azure Observability Module - Main Resources
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Name        = "${local.name_prefix}-observability"
    Environment = var.environment
    Project     = var.project_name
  })

  # Metric namespaces default to the resource type found in the resource ID,
  # e.g. Microsoft.Compute/virtualMachineScaleSets.
  monitored_namespace      = try(regex("/providers/([^/]+/[^/]+)/[^/]+$", var.monitored_resource_id)[0], null)
  http_monitored_namespace = try(regex("/providers/([^/]+/[^/]+)/[^/]+$", var.http_monitored_resource_id)[0], null)

  alert_emails = concat(var.alert_email != null ? [var.alert_email] : [], var.additional_alert_emails)
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

  lifecycle {
    precondition {
      condition     = var.sku != "CapacityReservation" || var.reservation_capacity_in_gb_per_day != null
      error_message = "reservation_capacity_in_gb_per_day is required when sku is CapacityReservation."
    }
  }
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

  daily_data_cap_in_gb                 = var.application_insights_daily_cap_gb
  daily_data_cap_notifications_enabled = !var.application_insights_disable_cap_notifications
  retention_in_days                    = var.application_insights_retention_days
  sampling_percentage                  = var.application_insights_sampling_percentage
  ip_masking_enabled                   = !var.application_insights_disable_ip_masking

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Monitor Action Group for Alerts
# -----------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "main" {
  name                = "${local.name_prefix}-action-group"
  resource_group_name = var.resource_group_name
  short_name          = substr(replace("${var.project_name}${var.environment}", "-", ""), 0, 12)

  dynamic "email_receiver" {
    for_each = local.alert_emails

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
# Metric Alerts on the monitored virtual machine or scale set
# -----------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "high_cpu" {
  count = var.enable_cpu_alert && var.monitored_resource_id != null ? 1 : 0

  name                = "${local.name_prefix}-high-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.monitored_resource_id]
  description         = "CPU usage is above ${var.cpu_threshold}%"
  severity            = var.cpu_alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size

  criteria {
    metric_namespace = coalesce(var.cpu_metric_namespace, local.monitored_namespace)
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

# Azure reports available rather than used memory, so the alert fires when the
# available share drops below the complement of the usage threshold.
resource "azurerm_monitor_metric_alert" "high_memory" {
  count = var.enable_memory_alert && var.monitored_resource_id != null ? 1 : 0

  name                = "${local.name_prefix}-high-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.monitored_resource_id]
  description         = "Memory usage is above ${var.memory_threshold}%"
  severity            = var.memory_alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size

  criteria {
    metric_namespace = coalesce(var.memory_metric_namespace, local.monitored_namespace)
    metric_name      = var.memory_metric_name
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100 - var.memory_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Disk Usage Alert (log query over VM insights data in the workspace)
# -----------------------------------------------------------------------------

# Azure has no platform metric for used disk space; the Azure Monitor Agent
# reports free space per mount point to the InsightsMetrics table.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "low_disk_space" {
  count = var.enable_disk_alert ? 1 : 0

  name                 = "${local.name_prefix}-low-disk-alert"
  resource_group_name  = var.resource_group_name
  location             = var.location
  scopes               = [azurerm_log_analytics_workspace.main.id]
  description          = "Disk usage is above ${var.disk_threshold}%"
  severity             = var.disk_alert_severity
  evaluation_frequency = var.alert_frequency
  window_duration      = var.alert_window_size

  # A new workspace has no InsightsMetrics table until the first agent reports.
  skip_query_validation = true

  criteria {
    query = join(" | ", [
      "InsightsMetrics",
      "where Origin == 'vm.azm.ms' and Namespace == 'LogicalDisk' and Name == 'FreeSpacePercentage'",
      "extend Disk = tostring(parse_json(Tags)['vm.azm.ms/mountId'])",
      "summarize UsedPercentage = 100 - min(Val) by bin(TimeGenerated, 5m), Computer, Disk",
    ])
    metric_measure_column   = "UsedPercentage"
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.disk_threshold

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "Disk"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.main.id]
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# HTTP Errors Alert on the monitored App Service or Function App
# -----------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "http_errors" {
  count = var.enable_http_errors_alert && var.http_monitored_resource_id != null ? 1 : 0

  name                = "${local.name_prefix}-http-errors-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.http_monitored_resource_id]
  description         = "HTTP 5xx responses exceed ${var.http_errors_threshold}"
  severity            = var.http_errors_alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size

  criteria {
    metric_namespace = coalesce(var.http_errors_metric_namespace, local.http_monitored_namespace)
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
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Azure Service Health events for the subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events    = var.service_health_events
      locations = length(var.service_health_locations) > 0 ? var.service_health_locations : null
      services  = length(var.service_health_services) > 0 ? var.service_health_services : null
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Azure Portal Dashboard
# -----------------------------------------------------------------------------

locals {
  dashboard_queries = [
    {
      title = "Computers without a heartbeat in the last 5 minutes"
      chart = "AnalyticsGrid"
      query = "Heartbeat | summarize LastHeartbeat = max(TimeGenerated) by Computer | where LastHeartbeat < ago(5m)"
    },
    {
      title = "CPU utilisation (%)"
      chart = "FrameControlChart"
      query = "InsightsMetrics | where Origin == 'vm.azm.ms' and Namespace == 'Processor' and Name == 'UtilizationPercentage' | summarize avg(Val) by Computer, bin(TimeGenerated, 5m) | render timechart"
    },
    {
      title = "Available memory (MB)"
      chart = "FrameControlChart"
      query = "InsightsMetrics | where Origin == 'vm.azm.ms' and Namespace == 'Memory' and Name == 'AvailableMB' | summarize avg(Val) by Computer, bin(TimeGenerated, 5m) | render timechart"
    },
    {
      title = "Free disk space (%)"
      chart = "FrameControlChart"
      query = "InsightsMetrics | where Origin == 'vm.azm.ms' and Namespace == 'LogicalDisk' and Name == 'FreeSpacePercentage' | summarize min(Val) by Computer, bin(TimeGenerated, 5m) | render timechart"
    },
    {
      title = "Failed control-plane operations"
      chart = "AnalyticsGrid"
      query = "AzureActivity | where ActivityStatusValue == 'Failure' | summarize Failures = count() by OperationNameValue, ResourceGroup | top 20 by Failures"
    },
    {
      title = "Application exceptions"
      chart = "AnalyticsGrid"
      query = "AppExceptions | summarize Exceptions = count() by AppRoleName, ProblemId | top 20 by Exceptions"
    },
  ]

  dashboard_overview_part = {
    position = { x = 0, y = 0, colSpan = 12, rowSpan = 2 }
    metadata = {
      type   = "Extension/HubsExtension/PartType/MarkdownPart"
      inputs = []
      settings = {
        content = {
          settings = {
            title    = "${var.project_name} (${var.environment})"
            subtitle = "Observability overview"
            content  = "Log Analytics workspace **${local.name_prefix}-law** in resource group **${var.resource_group_name}** (${var.location}). Tiles query the workspace over the last 24 hours."
          }
        }
      }
    }
  }

  # Two query tiles per row below the overview tile.
  dashboard_query_parts = [
    for index, tile in local.dashboard_queries : {
      position = { x = (index % 2) * 6, y = 2 + floor(index / 2) * 4, colSpan = 6, rowSpan = 4 }
      metadata = {
        type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
        inputs = [
          { name = "Scope", value = { resourceIds = [azurerm_log_analytics_workspace.main.id] }, isOptional = true },
          { name = "Version", value = "2.0", isOptional = true },
          { name = "TimeRange", value = "P1D", isOptional = true },
          { name = "Query", value = tile.query, isOptional = true },
          { name = "ControlType", value = tile.chart, isOptional = true },
          { name = "SpecificChart", value = tile.chart == "FrameControlChart" ? "Line" : null, isOptional = true },
          { name = "PartTitle", value = tile.title, isOptional = true },
          { name = "PartSubTitle", value = "${local.name_prefix}-law", isOptional = true },
          { name = "IsQueryContainTimeRange", value = false, isOptional = true },
        ]
        settings = {}
      }
    }
  ]

  dashboard_parts = concat([local.dashboard_overview_part], local.dashboard_query_parts)

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = { for index, part in local.dashboard_parts : tostring(index) => part }
      }
    }
    metadata = {
      model = {
        timeRange = {
          type  = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
          value = { relative = { duration = 24, timeUnit = 1 } }
        }
      }
    }
  })
}

resource "azurerm_portal_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0

  name                 = "${local.name_prefix}-dashboard"
  resource_group_name  = var.resource_group_name
  location             = var.location
  dashboard_properties = local.dashboard_properties

  tags = merge(local.common_tags, {
    "hidden-title" = "${var.project_name} ${var.environment} observability"
  })
}

# -----------------------------------------------------------------------------
# Diagnostic Settings for an existing resource (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "target" {
  count = var.diagnostic_setting_resource_id != null ? 1 : 0

  name                       = "${local.name_prefix}-diagnostic-setting"
  target_resource_id         = var.diagnostic_setting_resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = var.diagnostic_log_category_groups

    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = var.diagnostic_log_categories

    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = var.diagnostic_metric_categories

    content {
      category = enabled_metric.value
    }
  }

  lifecycle {
    precondition {
      condition     = length(var.diagnostic_log_category_groups) + length(var.diagnostic_log_categories) + length(var.diagnostic_metric_categories) > 0
      error_message = "A diagnostic setting needs at least one log category group, log category or metric category."
    }
  }
}
