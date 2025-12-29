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
  common_tags = merge(var.tags, {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  })

  # Create a map for custom policy definitions for easy lookup
  custom_policy_map = {
    for policy in azurerm_policy_definition.custom : policy.name => policy.id
  }

  # Filter assignments that need managed identity (for modify/deployIfNotExists effects)
  assignments_with_identity = [
    for assignment in var.policy_assignments : assignment
    if assignment.identity_type != null && assignment.identity_type != ""
  ]
}

#------------------------------------------------------------------------------
# Custom Policy Definitions
#------------------------------------------------------------------------------
resource "azurerm_policy_definition" "custom" {
  for_each = { for policy in var.custom_policies : policy.name => policy }

  name         = each.value.name
  policy_type  = "Custom"
  mode         = each.value.mode
  display_name = each.value.display_name
  description  = each.value.description

  metadata    = each.value.metadata != null ? jsonencode(each.value.metadata) : null
  policy_rule = jsonencode(each.value.policy_rule)
  parameters  = each.value.parameters != null ? jsonencode(each.value.parameters) : null
}

#------------------------------------------------------------------------------
# Policy Set Definitions (Initiatives)
#------------------------------------------------------------------------------
resource "azurerm_policy_set_definition" "initiative" {
  for_each = { for set in var.policy_set_definitions : set.name => set }

  name         = each.value.name
  policy_type  = "Custom"
  display_name = each.value.display_name
  description  = each.value.description

  metadata = jsonencode({
    category = "Custom"
    version  = "1.0.0"
  })

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_definition_references

    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      parameter_values     = policy_definition_reference.value.parameter_values != null ? jsonencode(policy_definition_reference.value.parameter_values) : null
      reference_id         = policy_definition_reference.value.reference_id
    }
  }

  depends_on = [azurerm_policy_definition.custom]
}

#------------------------------------------------------------------------------
# Policy Assignments - Subscription Scope
#------------------------------------------------------------------------------
resource "azurerm_subscription_policy_assignment" "subscription" {
  for_each = {
    for assignment in var.policy_assignments : assignment.name => assignment
    if can(regex("^/subscriptions/[^/]+$", assignment.scope))
  }

  name                 = each.value.name
  policy_definition_id = each.value.policy_definition_id
  subscription_id      = each.value.scope
  enforce              = each.value.enforce != null ? each.value.enforce : true
  location             = each.value.identity_type != null ? each.value.location : null

  parameters = each.value.parameters != null ? jsonencode({
    for k, v in each.value.parameters : k => { value = v }
  }) : null

  dynamic "identity" {
    for_each = each.value.identity_type != null ? [1] : []

    content {
      type = each.value.identity_type
    }
  }

  metadata = jsonencode(local.common_tags)

  depends_on = [
    azurerm_policy_definition.custom,
    azurerm_policy_set_definition.initiative
  ]
}

#------------------------------------------------------------------------------
# Policy Assignments - Resource Group Scope
#------------------------------------------------------------------------------
resource "azurerm_resource_group_policy_assignment" "resource_group" {
  for_each = {
    for assignment in var.policy_assignments : assignment.name => assignment
    if can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", assignment.scope))
  }

  name                 = each.value.name
  policy_definition_id = each.value.policy_definition_id
  resource_group_id    = each.value.scope
  enforce              = each.value.enforce != null ? each.value.enforce : true
  location             = each.value.identity_type != null ? each.value.location : null

  parameters = each.value.parameters != null ? jsonencode({
    for k, v in each.value.parameters : k => { value = v }
  }) : null

  dynamic "identity" {
    for_each = each.value.identity_type != null ? [1] : []

    content {
      type = each.value.identity_type
    }
  }

  metadata = jsonencode(local.common_tags)

  depends_on = [
    azurerm_policy_definition.custom,
    azurerm_policy_set_definition.initiative
  ]
}

#------------------------------------------------------------------------------
# Policy Assignments - Management Group Scope
#------------------------------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "management_group" {
  for_each = {
    for assignment in var.policy_assignments : assignment.name => assignment
    if can(regex("^/providers/Microsoft.Management/managementGroups/", assignment.scope))
  }

  name                 = each.value.name
  policy_definition_id = each.value.policy_definition_id
  management_group_id  = each.value.scope
  enforce              = each.value.enforce != null ? each.value.enforce : true
  location             = each.value.identity_type != null ? each.value.location : null

  parameters = each.value.parameters != null ? jsonencode({
    for k, v in each.value.parameters : k => { value = v }
  }) : null

  dynamic "identity" {
    for_each = each.value.identity_type != null ? [1] : []

    content {
      type = each.value.identity_type
    }
  }

  metadata = jsonencode(local.common_tags)

  depends_on = [
    azurerm_policy_definition.custom,
    azurerm_policy_set_definition.initiative
  ]
}

#------------------------------------------------------------------------------
# Policy Remediation - Subscription Scope
#------------------------------------------------------------------------------
resource "azurerm_subscription_policy_remediation" "subscription" {
  for_each = {
    for assignment in var.policy_assignments : assignment.name => assignment
    if var.enable_remediation && can(regex("^/subscriptions/[^/]+$", assignment.scope))
  }

  name                 = "${each.value.name}-remediation"
  subscription_id      = each.value.scope
  policy_assignment_id = azurerm_subscription_policy_assignment.subscription[each.key].id

  resource_discovery_mode = "ReEvaluateCompliance"
}

#------------------------------------------------------------------------------
# Policy Remediation - Resource Group Scope
#------------------------------------------------------------------------------
resource "azurerm_resource_group_policy_remediation" "resource_group" {
  for_each = {
    for assignment in var.policy_assignments : assignment.name => assignment
    if var.enable_remediation && can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", assignment.scope))
  }

  name                 = "${each.value.name}-remediation"
  resource_group_id    = each.value.scope
  policy_assignment_id = azurerm_resource_group_policy_assignment.resource_group[each.key].id

  resource_discovery_mode = "ReEvaluateCompliance"
}

#------------------------------------------------------------------------------
# Policy Remediation - Management Group Scope
#------------------------------------------------------------------------------
resource "azurerm_management_group_policy_remediation" "management_group" {
  for_each = {
    for assignment in var.policy_assignments : assignment.name => assignment
    if var.enable_remediation && can(regex("^/providers/Microsoft.Management/managementGroups/", assignment.scope))
  }

  name                 = "${each.value.name}-remediation"
  management_group_id  = each.value.scope
  policy_assignment_id = azurerm_management_group_policy_assignment.management_group[each.key].id

  resource_discovery_mode = "ReEvaluateCompliance"
}
