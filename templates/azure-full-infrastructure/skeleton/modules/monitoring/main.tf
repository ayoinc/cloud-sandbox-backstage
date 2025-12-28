# =============================================================================
# MONITORING MODULE FOR AZURE FULL INFRASTRUCTURE
# =============================================================================
# Creates Log Analytics and Application Insights
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "enable_log_analytics" {
  type    = bool
  default = true
}

variable "enable_app_insights" {
  type    = bool
  default = false
}

variable "retention_in_days" {
  type    = number
  default = 30
}

variable "sku" {
  type    = string
  default = "PerGB2018"
}

variable "tags" {
  type    = map(string)
  default = {}
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  count = var.enable_log_analytics ? 1 : 0

  name                = "${var.name_prefix}-log"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Application Insights
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  count = var.enable_app_insights ? 1 : 0

  name                = "${var.name_prefix}-appi"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].id : null
  application_type    = "web"
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "log_analytics_id" {
  value = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].id : null
}

output "log_analytics_workspace_id" {
  value = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].workspace_id : null
}

output "log_analytics_primary_key" {
  value     = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].primary_shared_key : null
  sensitive = true
}

output "app_insights_id" {
  value = var.enable_app_insights ? azurerm_application_insights.main[0].id : null
}

output "app_insights_instrumentation_key" {
  value     = var.enable_app_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive = true
}

output "app_insights_connection_string" {
  value     = var.enable_app_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive = true
}
