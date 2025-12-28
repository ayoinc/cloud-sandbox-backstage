# =============================================================================
# GOVERNANCE MODULE
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
variable "enable_budget_alerts" { type = bool; default = true }
variable "monthly_budget" { type = number; default = 1000 }
variable "enable_tagging_policy" { type = bool; default = true }
variable "required_tags" { type = list(string); default = ["Project", "Environment"] }

data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_resource_group" "main" {
  count             = var.enable_budget_alerts ? 1 : 0
  name              = "budget-${var.project}-${var.environment}"
  resource_group_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  amount     = var.monthly_budget
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled   = true
    threshold = 80
    operator  = "GreaterThanOrEqualTo"
    contact_emails = []
  }

  notification {
    enabled   = true
    threshold = 100
    operator  = "GreaterThanOrEqualTo"
    contact_emails = []
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}

output "budget_id" {
  value = var.enable_budget_alerts ? azurerm_consumption_budget_resource_group.main[0].id : null
}
