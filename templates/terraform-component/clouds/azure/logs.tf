# -----------------------------------------------------------------------------
# Log workspace: Log Analytics workspace
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Number of days logs are kept, between 30 and 730."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = module.naming.standard["log"]
  resource_group_name = local.resource_group_name
  location            = var.region
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = module.tagging.tags
}

output "log_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_workspace_name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}
