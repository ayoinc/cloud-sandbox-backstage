# =============================================================================
# MONITORING MODULE
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

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }
variable "retention_in_days" { type = number; default = 30 }
variable "sku" { type = string; default = "PerGB2018" }

locals {
  workspace_name = "log-${var.project}-${var.environment}-${var.location}"
  app_insights_name = "appi-${var.project}-${var.environment}-${var.location}"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

output "workspace_id" { value = azurerm_log_analytics_workspace.main.id }
output "workspace_name" { value = azurerm_log_analytics_workspace.main.name }
output "workspace_key" { value = azurerm_log_analytics_workspace.main.primary_shared_key; sensitive = true }
output "app_insights_id" { value = azurerm_application_insights.main.id }
output "app_insights_connection_string" { value = azurerm_application_insights.main.connection_string; sensitive = true }
output "app_insights_instrumentation_key" { value = azurerm_application_insights.main.instrumentation_key; sensitive = true }
