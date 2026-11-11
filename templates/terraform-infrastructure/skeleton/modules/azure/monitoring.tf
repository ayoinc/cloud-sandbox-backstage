locals {
  # Flow logs need the workspace even when monitoring is off.
  log_workspace_enabled = var.enable_monitoring || local.flow_logs_enabled

  # A workspace keeps data available for queries for 30 to 730 days. Longer
  # periods are met by an archive: resource logs are written to the log
  # storage account as well, and the container log tables of the workspace
  # get long-term retention.
  log_workspace_days  = min(max(var.log_retention_days, 30), 730)
  log_archive_enabled = var.log_retention_days > 730

  # Holds the flow logs and the archive of the resource logs.
  log_storage_enabled = local.flow_logs_enabled || (var.enable_monitoring && local.log_archive_enabled)

  # Tables that container insights fills with logs of the workloads. Their
  # long-term retention is set in whole years: the first period that is not
  # shorter than log_retention_days.
  container_log_tables     = var.enable_monitoring && var.enable_kubernetes && local.log_archive_enabled ? ["ContainerLogV2", "KubeEvents"] : []
  log_table_retention_days = [for days in [1095, 1460, 1826, 2191, 2556, 2922, 3288, 3653, 4018, 4383] : days if days >= var.log_retention_days][0]

  # Resource logs that go to the workspace. AKS lists its categories: the
  # complete audit log of the API server is large and rarely needed.
  diagnostic_candidates = {
    key-vault = {
      enabled         = local.key_vault_enabled
      target_id       = one(azurerm_key_vault.this[*].id)
      category_groups = ["allLogs"]
      categories      = []
    }
    kubernetes = {
      enabled         = var.enable_kubernetes
      target_id       = one(azurerm_kubernetes_cluster.this[*].id)
      category_groups = []
      categories      = ["kube-apiserver", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "guard"]
    }
    database = {
      enabled = var.enable_database
      # Azure Managed Redis logs on its database, not on the cluster.
      target_id       = local.redis_enabled ? "${azurerm_managed_redis.this[0].id}/databases/default" : local.database_resource_id
      category_groups = ["allLogs"]
      categories      = []
    }
    storage = {
      enabled         = var.enable_storage
      target_id       = var.enable_storage ? "${azurerm_storage_account.this[0].id}/blobServices/default" : null
      category_groups = ["allLogs"]
      categories      = []
    }
    cdn = {
      enabled         = local.cdn_enabled
      target_id       = one(azurerm_cdn_frontdoor_profile.this[*].id)
      category_groups = ["allLogs"]
      categories      = []
    }
    registry = {
      enabled         = local.registry_enabled
      target_id       = one(azurerm_container_registry.this[*].id)
      category_groups = ["allLogs"]
      categories      = []
    }
  }

  diagnostics = {
    for name, target in local.diagnostic_candidates : name => target
    if target.enabled && var.enable_monitoring
  }
}

# -----------------------------------------------------------------------------
# Logs
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  count = local.log_workspace_enabled ? 1 : 0

  name                = "${var.name_prefix}-logs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = local.log_workspace_days

  tags = local.tags
}

# Keeps the workspace tables with container logs for at least
# log_retention_days. After the retention of the workspace the data moves to
# long-term retention, where search jobs can still read it.
resource "azurerm_log_analytics_workspace_table" "container_logs" {
  for_each = toset(local.container_log_tables)

  name                    = each.key
  workspace_id            = azurerm_log_analytics_workspace.this[0].id
  total_retention_in_days = local.log_table_retention_days
}

# Network Watcher and Azure Monitor write here as trusted Azure services;
# nothing else gets through the firewall of the account.
resource "azurerm_storage_account" "logs" {
  count = local.log_storage_enabled ? 1 : 0

  name                     = "${substr(local.compact_prefix, 0, 14)}lg${local.suffix}"
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = var.enable_disaster_recovery ? "GRS" : "LRS"

  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  dynamic "identity" {
    for_each = var.enable_kms ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.encryption[0].id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.enable_kms ? [1] : []

    content {
      key_vault_key_id          = local.kms_key_id
      user_assigned_identity_id = azurerm_user_assigned_identity.encryption[0].id
    }
  }

  tags = local.tags

  depends_on = [time_sleep.encryption_access]
}

# Flow logs are block blobs and resource logs append blobs. Both are deleted
# once they are older than log_retention_days.
resource "azurerm_storage_management_policy" "logs" {
  count = local.log_storage_enabled ? 1 : 0

  storage_account_id = azurerm_storage_account.logs[0].id

  rule {
    name    = "expire-logs"
    enabled = true

    filters {
      blob_types = ["blockBlob", "appendBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.log_retention_days
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = local.diagnostics

  name                       = "${var.name_prefix}-${each.key}"
  target_resource_id         = each.value.target_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this[0].id
  storage_account_id         = local.log_archive_enabled ? azurerm_storage_account.logs[0].id : null

  dynamic "enabled_log" {
    for_each = each.value.category_groups

    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.categories

    content {
      category = enabled_log.value
    }
  }
}

# Container insights: the monitoring agent of the cluster sends container
# logs and inventory to the workspace according to this rule.
resource "azurerm_monitor_data_collection_rule" "container_insights" {
  count = var.enable_monitoring && var.enable_kubernetes ? 1 : 0

  name                = "${var.name_prefix}-container-insights"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  description         = "Container insights of the ${var.name_prefix} cluster."

  destinations {
    log_analytics {
      name                  = "workspace"
      workspace_resource_id = azurerm_log_analytics_workspace.this[0].id
    }
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]

      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          enableContainerLogV2   = true
        }
      })
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["workspace"]
  }

  tags = local.tags
}

resource "azurerm_monitor_data_collection_rule_association" "container_insights" {
  count = var.enable_monitoring && var.enable_kubernetes ? 1 : 0

  name                    = "ContainerInsightsExtension"
  target_resource_id      = azurerm_kubernetes_cluster.this[0].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container_insights[0].id
  description             = "Sends container insights of the cluster to the Log Analytics workspace."
}

# -----------------------------------------------------------------------------
# Dashboard
# -----------------------------------------------------------------------------

# Workbooks are named with a UUID; the display name is what the portal shows.
resource "random_uuid" "workbook" {
  count = var.enable_monitoring ? 1 : 0
}

resource "azurerm_application_insights_workbook" "this" {
  count = var.enable_monitoring ? 1 : 0

  name                = random_uuid.workbook[0].result
  display_name        = "${var.name_prefix} overview"
  description         = "Log volume and resource logs of the ${var.name_prefix} ${var.environment} stack."
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  category            = "workbook"
  source_id           = lower(azurerm_log_analytics_workspace.this[0].id)

  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type    = 1
        name    = "introduction"
        content = { json = "## ${var.name_prefix} (${var.environment})\nLogs collected in the Log Analytics workspace of this stack." }
      },
      {
        type = 3
        name = "ingestion-over-time"
        content = {
          version       = "KqlItem/1.0"
          title         = "Ingested data by table (MB)"
          query         = "Usage | summarize IngestedMB = sum(Quantity) by DataType, bin(TimeGenerated, 1h)"
          size          = 0
          timeContext   = { durationMs = 86400000 }
          queryType     = 0
          resourceType  = "microsoft.operationalinsights/workspaces"
          visualization = "timechart"
        }
      },
      {
        type = 3
        name = "resource-logs-by-category"
        content = {
          version       = "KqlItem/1.0"
          title         = "Resource log records by category"
          query         = "union isfuzzy=true (datatable(TimeGenerated: datetime, Category: string) []), AzureDiagnostics | summarize Records = count() by Category, bin(TimeGenerated, 1h)"
          size          = 0
          timeContext   = { durationMs = 86400000 }
          queryType     = 0
          resourceType  = "microsoft.operationalinsights/workspaces"
          visualization = "barchart"
        }
      },
      {
        type = 3
        name = "largest-tables"
        content = {
          version       = "KqlItem/1.0"
          title         = "Largest tables of the last day (MB)"
          query         = "Usage | summarize IngestedMB = sum(Quantity) by DataType | top 10 by IngestedMB desc"
          size          = 0
          timeContext   = { durationMs = 86400000 }
          queryType     = 0
          resourceType  = "microsoft.operationalinsights/workspaces"
          visualization = "table"
        }
      },
    ]
    isLocked            = false
    fallbackResourceIds = [lower(azurerm_log_analytics_workspace.this[0].id)]
  })

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Managed Prometheus and Grafana
# -----------------------------------------------------------------------------

resource "azurerm_monitor_workspace" "this" {
  count = var.enable_managed_prometheus ? 1 : 0

  name                = "${var.name_prefix}-prometheus"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

# The metrics agent of the cluster sends what it scrapes to this endpoint,
# and the rule forwards it to the Azure Monitor workspace.
resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  count = var.enable_managed_prometheus && var.enable_kubernetes ? 1 : 0

  name                = "${var.name_prefix}-prometheus"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  kind                = "Linux"

  tags = local.tags
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  count = var.enable_managed_prometheus && var.enable_kubernetes ? 1 : 0

  name                        = "${var.name_prefix}-prometheus"
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  kind                        = "Linux"
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus[0].id
  description                 = "Prometheus metrics of the ${var.name_prefix} cluster."

  destinations {
    monitor_account {
      name               = "prometheus"
      monitor_account_id = azurerm_monitor_workspace.this[0].id
    }
  }

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["prometheus"]
  }

  tags = local.tags
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  count = var.enable_managed_prometheus && var.enable_kubernetes ? 1 : 0

  name                    = "${var.name_prefix}-prometheus"
  target_resource_id      = azurerm_kubernetes_cluster.this[0].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus[0].id
  description             = "Sends Prometheus metrics of the cluster to the Azure Monitor workspace."
}

resource "azurerm_dashboard_grafana" "this" {
  count = var.enable_managed_prometheus ? 1 : 0

  name                  = "amg-${substr(local.compact_prefix, 0, 10)}-${local.suffix}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  grafana_major_version = "12"
  sku                   = "Standard"

  # Users sign in with Microsoft Entra ID; API keys are off.
  api_key_enabled = false

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.this[0].id
  }

  tags = local.tags
}

# Grafana queries Prometheus metrics and the Azure Monitor data of the
# resource group with its own identity.
resource "azurerm_role_assignment" "grafana_prometheus" {
  count = var.enable_managed_prometheus ? 1 : 0

  scope                = azurerm_monitor_workspace.this[0].id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.this[0].identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "grafana_monitoring" {
  count = var.enable_managed_prometheus ? 1 : 0

  scope                = azurerm_resource_group.this.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.this[0].identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# The identity that creates the stack administers Grafana and grants access
# to others.
resource "azurerm_role_assignment" "grafana_admin" {
  count = var.enable_managed_prometheus ? 1 : 0

  scope                = azurerm_dashboard_grafana.this[0].id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

# -----------------------------------------------------------------------------
# Alerts
# -----------------------------------------------------------------------------

locals {
  relational_metric_namespace = local.postgresql_enabled ? "Microsoft.DBforPostgreSQL/flexibleServers" : "Microsoft.DBforMySQL/flexibleServers"

  metric_alert_candidates = {
    database-cpu = {
      enabled     = local.postgresql_enabled || local.mysql_enabled
      scope       = local.database_resource_id
      namespace   = local.relational_metric_namespace
      metric      = "cpu_percent"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 80
      dimensions  = {}
      description = "CPU of the database server is above 80 percent."
    }
    database-storage = {
      enabled     = local.postgresql_enabled || local.mysql_enabled
      scope       = local.database_resource_id
      namespace   = local.relational_metric_namespace
      metric      = "storage_percent"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 85
      dimensions  = {}
      description = "Storage of the database server is more than 85 percent full."
    }
    database-throttling = {
      enabled     = local.cosmos_enabled
      scope       = local.database_resource_id
      namespace   = "Microsoft.DocumentDB/databaseAccounts"
      metric      = "TotalRequests"
      aggregation = "Count"
      operator    = "GreaterThan"
      threshold   = 100
      dimensions  = { StatusCode = ["429"] }
      description = "Cosmos DB rejects requests because the throughput limit is reached."
    }
    database-memory = {
      enabled     = local.redis_enabled
      scope       = local.database_resource_id
      namespace   = "Microsoft.Cache/redisEnterprise"
      metric      = "usedmemorypercentage"
      aggregation = "Maximum"
      operator    = "GreaterThan"
      threshold   = 85
      dimensions  = {}
      description = "Redis uses more than 85 percent of its memory."
    }
    kubernetes-node-cpu = {
      enabled     = var.enable_kubernetes
      scope       = one(azurerm_kubernetes_cluster.this[*].id)
      namespace   = "Microsoft.ContainerService/managedClusters"
      metric      = "node_cpu_usage_percentage"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 85
      dimensions  = {}
      description = "Average CPU of the cluster nodes is above 85 percent."
    }
    kubernetes-node-memory = {
      enabled     = var.enable_kubernetes
      scope       = one(azurerm_kubernetes_cluster.this[*].id)
      namespace   = "Microsoft.ContainerService/managedClusters"
      metric      = "node_memory_working_set_percentage"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 85
      dimensions  = {}
      description = "Average memory of the cluster nodes is above 85 percent."
    }
    cdn-server-errors = {
      enabled     = local.cdn_enabled
      scope       = one(azurerm_cdn_frontdoor_profile.this[*].id)
      namespace   = "Microsoft.Cdn/profiles"
      metric      = "Percentage5XX"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 5
      dimensions  = {}
      description = "More than 5 percent of the Front Door responses are server errors."
    }
    waf-blocked-requests = {
      enabled     = local.cdn_enabled && var.enable_waf
      scope       = one(azurerm_cdn_frontdoor_profile.this[*].id)
      namespace   = "Microsoft.Cdn/profiles"
      metric      = "WebApplicationFirewallRequestCount"
      aggregation = "Total"
      operator    = "GreaterThan"
      threshold   = 100
      dimensions  = { Action = ["Block"] }
      description = "The web application firewall blocks an unusual number of requests."
    }
    storage-availability = {
      enabled     = var.enable_storage
      scope       = one(azurerm_storage_account.this[*].id)
      namespace   = "Microsoft.Storage/storageAccounts"
      metric      = "Availability"
      aggregation = "Average"
      operator    = "LessThan"
      threshold   = 99
      dimensions  = {}
      description = "Availability of the storage account is below 99 percent."
    }
  }

  metric_alerts = {
    for name, alert in local.metric_alert_candidates : name => alert
    if alert.enabled && var.enable_alerting
  }
}

resource "azurerm_monitor_action_group" "this" {
  count = var.enable_alerting ? 1 : 0

  name                = "${var.name_prefix}-alerts"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = substr(local.compact_prefix, 0, 12)

  dynamic "email_receiver" {
    for_each = var.alert_email != null ? [var.alert_email] : []

    content {
      name                    = "email"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.metric_alerts

  name                = "${var.name_prefix}-${each.key}"
  resource_group_name = azurerm_resource_group.this.name
  description         = each.value.description
  scopes              = [each.value.scope]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = each.value.namespace
    metric_name      = each.value.metric
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold

    dynamic "dimension" {
      for_each = each.value.dimensions

      content {
        name     = dimension.key
        operator = "Include"
        values   = dimension.value
      }
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.this[0].id
  }

  tags = local.tags
}
