# Azure Monitoring

## Log Analytics Module

Creates Log Analytics workspace with solutions and data collection.

### Usage

```hcl
module "monitoring" {
  source = "path/to/azure/resources/monitoring/log-analytics"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  project             = "myapp"
  environment         = "prod"
  
  sku               = "PerGB2018"
  retention_in_days = 90
  daily_quota_gb    = -1  # Unlimited
  
  # Built-in Solutions
  enable_container_insights = true
  enable_vm_insights        = true
  enable_security_center    = true
  
  # Additional Solutions
  solutions = [
    {
      solution_name = "AzureActivity"
      publisher     = "Microsoft"
      product       = "OMSGallery/AzureActivity"
    }
  ]
  
  tags = module.tags.azure_tags
}
```

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `sku` | string | "PerGB2018" | Pricing tier |
| `retention_in_days` | number | 30 | Data retention |
| `daily_quota_gb` | number | -1 | Daily ingestion limit |
| `enable_container_insights` | bool | false | Container monitoring |
| `enable_vm_insights` | bool | false | VM monitoring |

### Outputs

| Output | Description |
|--------|-------------|
| `workspace_id` | Workspace resource ID |
| `workspace_customer_id` | Customer ID for agents |
| `primary_shared_key` | Shared key (sensitive) |

### Environment-Specific Retention

| Environment | Retention |
|-------------|-----------|
| Dev | 30 days |
| Staging | 60 days |
| Prod | 90 days |

### Integrating with Other Resources

```hcl
# AKS with Container Insights
module "aks" {
  # ...
  enable_oms_agent           = true
  log_analytics_workspace_id = module.monitoring.workspace_id
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-keyvault"
  target_resource_id         = module.keyvault.key_vault_id
  log_analytics_workspace_id = module.monitoring.workspace_id

  enabled_log {
    category = "AuditEvent"
  }
  
  metric {
    category = "AllMetrics"
  }
}
```

### Alerting

```hcl
resource "azurerm_monitor_action_group" "critical" {
  name                = "ag-critical-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "critical"

  email_receiver {
    name          = "oncall"
    email_address = "oncall@company.com"
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "alert-high-cpu"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [module.aks.cluster_id]
  
  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
}
```
