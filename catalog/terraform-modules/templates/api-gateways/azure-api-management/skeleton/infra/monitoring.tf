locals {
  # Application Insights stores its data in a Log Analytics workspace, so the
  # workspace exists when either option is enabled.
  workspace_enabled = var.enable_log_analytics || var.enable_application_insights
}

# Named log-<service_name>-<environment>-<location> by the module.
module "log_analytics" {
  count  = local.workspace_enabled ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/log-analytics?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  project             = var.service_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

module "application_insights" {
  count  = var.enable_application_insights ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/app-insights?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  name                = "appi-${var.service_name}-${var.environment}"
  project_name        = var.service_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  workspace_id        = module.log_analytics[0].workspace_id
  tags                = var.tags
}

resource "azurerm_api_management_logger" "application_insights" {
  count = var.enable_application_insights ? 1 : 0

  name                = "applicationinsights"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = module.resource_group.name
  resource_id         = module.application_insights[0].app_insights_id

  application_insights {
    connection_string = module.application_insights[0].connection_string
  }
}

# Request telemetry of every API.
resource "azurerm_api_management_diagnostic" "application_insights" {
  count = var.enable_application_insights ? 1 : 0

  identifier                = "applicationinsights"
  api_management_name       = azurerm_api_management.this.name
  resource_group_name       = module.resource_group.name
  api_management_logger_id  = azurerm_api_management_logger.application_insights[0].id
  sampling_percentage       = var.application_insights_sampling_percentage
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"
}

# Gateway logs go to the resource-specific table ApiManagementGatewayLogs.
module "diagnostic_settings" {
  count  = var.enable_log_analytics ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/diagnostic-settings?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  name                           = "diag-${var.service_name}"
  project_name                   = var.service_name
  environment                    = var.environment
  target_resource_id             = azurerm_api_management.this.id
  log_analytics_workspace_id     = module.log_analytics[0].workspace_id
  log_analytics_destination_type = "Dedicated"
  enabled_logs                   = [{ category = "GatewayLogs" }]
  metrics                        = [{ category = "AllMetrics" }]
}
