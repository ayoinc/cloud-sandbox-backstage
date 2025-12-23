terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

resource "azurerm_management_group" "this" {
  for_each = var.management_groups

  name                       = each.key
  display_name               = each.value.display_name
  parent_management_group_id = each.value.parent_management_group_id
}

resource "azurerm_policy_definition" "this" {
  for_each = var.policy_definitions

  name                = each.key
  policy_type         = "Custom"
  mode                = each.value.mode
  display_name        = each.value.display_name
  description         = each.value.description
  management_group_id = each.value.management_group_id
  policy_rule         = each.value.policy_rule
  parameters          = each.value.parameters
  metadata            = each.value.metadata
}

resource "azurerm_policy_set_definition" "this" {
  for_each = var.policy_set_definitions

  name                = each.key
  policy_type         = "Custom"
  display_name        = each.value.display_name
  description         = each.value.description
  management_group_id = each.value.management_group_id
  parameters          = each.value.parameters
  metadata            = each.value.metadata

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_definition_references
    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      parameter_values     = policy_definition_reference.value.parameter_values
      reference_id         = policy_definition_reference.value.reference_id
    }
  }
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = var.management_group_policy_assignments

  name                 = each.key
  management_group_id  = each.value.management_group_id
  policy_definition_id = each.value.policy_definition_id
  display_name         = each.value.display_name
  description          = each.value.description
  enforce              = each.value.enforce
  location             = each.value.location
  parameters           = each.value.parameters
  not_scopes           = each.value.not_scopes

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_messages
    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = non_compliance_message.value.policy_definition_reference_id
    }
  }
}

resource "azurerm_subscription_policy_assignment" "this" {
  for_each = var.subscription_policy_assignments

  name                 = each.key
  subscription_id      = each.value.subscription_id
  policy_definition_id = each.value.policy_definition_id
  display_name         = each.value.display_name
  description          = each.value.description
  enforce              = each.value.enforce
  location             = each.value.location
  parameters           = each.value.parameters
  not_scopes           = each.value.not_scopes

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_messages
    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = non_compliance_message.value.policy_definition_reference_id
    }
  }
}

resource "azurerm_resource_group_policy_assignment" "this" {
  for_each = var.resource_group_policy_assignments

  name                 = each.key
  resource_group_id    = each.value.resource_group_id
  policy_definition_id = each.value.policy_definition_id
  display_name         = each.value.display_name
  description          = each.value.description
  enforce              = each.value.enforce
  location             = each.value.location
  parameters           = each.value.parameters
  not_scopes           = each.value.not_scopes

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_messages
    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = non_compliance_message.value.policy_definition_reference_id
    }
  }
}

resource "azurerm_policy_remediation" "management_group" {
  for_each = var.management_group_remediations

  name                    = each.key
  management_group_id     = each.value.management_group_id
  policy_assignment_id    = each.value.policy_assignment_id
  policy_definition_id    = each.value.policy_definition_id
  location_filters        = each.value.location_filters
  resource_discovery_mode = each.value.resource_discovery_mode
}

resource "azurerm_policy_remediation" "subscription" {
  for_each = var.subscription_remediations

  name                           = each.key
  subscription_id                = each.value.subscription_id
  policy_assignment_id           = each.value.policy_assignment_id
  policy_definition_reference_id = each.value.policy_definition_reference_id
  location_filters               = each.value.location_filters
  resource_discovery_mode        = each.value.resource_discovery_mode
}

resource "azurerm_policy_remediation" "resource_group" {
  for_each = var.resource_group_remediations

  name                           = each.key
  resource_group_id              = each.value.resource_group_id
  policy_assignment_id           = each.value.policy_assignment_id
  policy_definition_reference_id = each.value.policy_definition_reference_id
  location_filters               = each.value.location_filters
  resource_discovery_mode        = each.value.resource_discovery_mode
}

resource "azurerm_management_group_subscription_association" "this" {
  for_each = var.subscription_associations

  management_group_id = each.value.management_group_id
  subscription_id     = each.value.subscription_id
}

resource "azurerm_role_assignment" "management_group" {
  for_each = var.management_group_role_assignments

  scope                = each.value.management_group_id
  role_definition_name = each.value.role_definition_name
  role_definition_id   = each.value.role_definition_id
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
}
