# =============================================================================
# Governance Module
# =============================================================================
# Monthly budget with alerts, and tag policies in audit mode, for one resource
# group.
# =============================================================================

locals {
  # Built-in policy "Require a tag on resources".
  require_tag_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
}

resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "budget-${var.name}-${var.environment}"
  resource_group_id = var.resource_group_id
  amount            = var.monthly_budget
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 80
    threshold_type = "Actual"
    contact_roles  = var.budget_contact_roles
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 100
    threshold_type = "Forecasted"
    contact_roles  = var.budget_contact_roles
  }

  lifecycle {
    # The start date is the month the budget was created in.
    ignore_changes = [time_period]
  }
}

# Resources missing a required tag are reported as non-compliant; nothing is
# denied, so services that create untagged helper resources keep working.
resource "azurerm_resource_group_policy_assignment" "require_tag" {
  for_each = toset(var.required_tags)

  name                 = "require-tag-${lower(each.value)}"
  display_name         = "Require the ${each.value} tag on resources"
  resource_group_id    = var.resource_group_id
  policy_definition_id = local.require_tag_policy_id
  enforce              = false

  parameters = jsonencode({
    tagName = { value = each.value }
  })
}
