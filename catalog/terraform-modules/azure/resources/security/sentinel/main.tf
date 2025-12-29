terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Sentinel Onboarding
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "this" {
  workspace_id                 = var.log_analytics_workspace_id
  customer_managed_key_enabled = false
}

# Azure Active Directory Data Connector
resource "azurerm_sentinel_data_connector_azure_active_directory" "this" {
  count = var.enable_aad_connector ? 1 : 0

  name                       = "${local.name_prefix}-aad-connector"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# Azure Security Center Data Connector
resource "azurerm_sentinel_data_connector_azure_security_center" "this" {
  count = var.enable_asc_connector ? 1 : 0

  name                       = "${local.name_prefix}-asc-connector"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# Microsoft Cloud App Security Data Connector
resource "azurerm_sentinel_data_connector_microsoft_cloud_app_security" "this" {
  count = var.enable_mcas_connector ? 1 : 0

  name                       = "${local.name_prefix}-mcas-connector"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id
  alerts_enabled             = true
  discovery_logs_enabled     = true

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# Office 365 Data Connector
resource "azurerm_sentinel_data_connector_office_365" "this" {
  count = var.enable_office365_connector ? 1 : 0

  name                       = "${local.name_prefix}-office365-connector"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id
  exchange_enabled           = var.office365_exchange_enabled
  sharepoint_enabled         = var.office365_sharepoint_enabled
  teams_enabled              = var.office365_teams_enabled

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# Threat Intelligence Data Connector
resource "azurerm_sentinel_data_connector_threat_intelligence" "this" {
  count = var.enable_threat_intelligence_connector ? 1 : 0

  name                       = "${local.name_prefix}-ti-connector"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# Scheduled Alert Rules
resource "azurerm_sentinel_alert_rule_scheduled" "this" {
  for_each = { for rule in var.alert_rules : rule.name => rule }

  name                       = each.value.name
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id
  display_name               = each.value.display_name
  severity                   = each.value.severity
  query                      = each.value.query
  query_frequency            = each.value.query_frequency
  query_period               = each.value.query_period
  trigger_operator           = each.value.trigger_operator
  trigger_threshold          = each.value.trigger_threshold
  enabled                    = each.value.enabled

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}

# Automation Rules
resource "azurerm_sentinel_automation_rule" "this" {
  for_each = { for rule in var.automation_rules : rule.name => rule }

  name                       = each.value.name
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id
  display_name               = each.value.display_name
  order                      = each.value.order
  enabled                    = true

  dynamic "condition_json" {
    for_each = each.value.condition_json != null ? [each.value.condition_json] : []
    content {
      # Use condition_json for complex conditions
    }
  }

  dynamic "action_incident" {
    for_each = each.value.action_incident != null ? [each.value.action_incident] : []
    content {
      order                  = action_incident.value.order
      status                 = lookup(action_incident.value, "status", null)
      classification         = lookup(action_incident.value, "classification", null)
      classification_comment = lookup(action_incident.value, "classification_comment", null)
      labels                 = lookup(action_incident.value, "labels", null)
      owner_id               = lookup(action_incident.value, "owner_id", null)
      severity               = lookup(action_incident.value, "severity", null)
    }
  }

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.this]
}
