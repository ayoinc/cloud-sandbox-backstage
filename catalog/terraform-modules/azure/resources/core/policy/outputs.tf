#------------------------------------------------------------------------------
# Policy Definition Outputs
#------------------------------------------------------------------------------
output "policy_definition_ids" {
  description = "Map of custom policy definition names to their IDs."
  value = {
    for name, policy in azurerm_policy_definition.custom : name => policy.id
  }
}

output "policy_definitions" {
  description = "Map of custom policy definitions with their full details."
  value = {
    for name, policy in azurerm_policy_definition.custom : name => {
      id           = policy.id
      name         = policy.name
      display_name = policy.display_name
      policy_type  = policy.policy_type
      mode         = policy.mode
    }
  }
}

#------------------------------------------------------------------------------
# Policy Set Definition (Initiative) Outputs
#------------------------------------------------------------------------------
output "policy_set_definition_ids" {
  description = "Map of policy set definition names to their IDs."
  value = {
    for name, set in azurerm_policy_set_definition.initiative : name => set.id
  }
}

output "policy_set_definitions" {
  description = "Map of policy set definitions with their full details."
  value = {
    for name, set in azurerm_policy_set_definition.initiative : name => {
      id           = set.id
      name         = set.name
      display_name = set.display_name
      policy_type  = set.policy_type
    }
  }
}

#------------------------------------------------------------------------------
# Policy Assignment Outputs
#------------------------------------------------------------------------------
output "policy_assignment_ids" {
  description = "Map of policy assignment names to their IDs, organized by scope type."
  value = {
    subscription = {
      for name, assignment in azurerm_subscription_policy_assignment.subscription : name => assignment.id
    }
    resource_group = {
      for name, assignment in azurerm_resource_group_policy_assignment.resource_group : name => assignment.id
    }
    management_group = {
      for name, assignment in azurerm_management_group_policy_assignment.management_group : name => assignment.id
    }
  }
}

output "policy_assignments" {
  description = "Map of all policy assignments with their full details."
  value = merge(
    {
      for name, assignment in azurerm_subscription_policy_assignment.subscription : name => {
        id                   = assignment.id
        name                 = assignment.name
        scope                = assignment.subscription_id
        scope_type           = "subscription"
        policy_definition_id = assignment.policy_definition_id
        enforce              = assignment.enforce
        identity             = try(assignment.identity[0], null)
      }
    },
    {
      for name, assignment in azurerm_resource_group_policy_assignment.resource_group : name => {
        id                   = assignment.id
        name                 = assignment.name
        scope                = assignment.resource_group_id
        scope_type           = "resource_group"
        policy_definition_id = assignment.policy_definition_id
        enforce              = assignment.enforce
        identity             = try(assignment.identity[0], null)
      }
    },
    {
      for name, assignment in azurerm_management_group_policy_assignment.management_group : name => {
        id                   = assignment.id
        name                 = assignment.name
        scope                = assignment.management_group_id
        scope_type           = "management_group"
        policy_definition_id = assignment.policy_definition_id
        enforce              = assignment.enforce
        identity             = try(assignment.identity[0], null)
      }
    }
  )
}

#------------------------------------------------------------------------------
# Remediation Outputs
#------------------------------------------------------------------------------
output "remediation_ids" {
  description = "Map of remediation task names to their IDs, organized by scope type."
  value = {
    subscription = {
      for name, remediation in azurerm_subscription_policy_remediation.subscription : name => remediation.id
    }
    resource_group = {
      for name, remediation in azurerm_resource_group_policy_remediation.resource_group : name => remediation.id
    }
    management_group = {
      for name, remediation in azurerm_management_group_policy_remediation.management_group : name => remediation.id
    }
  }
}

output "remediations" {
  description = "Map of all remediation tasks with their full details."
  value = merge(
    {
      for name, remediation in azurerm_subscription_policy_remediation.subscription : name => {
        id                   = remediation.id
        name                 = remediation.name
        scope                = remediation.subscription_id
        scope_type           = "subscription"
        policy_assignment_id = remediation.policy_assignment_id
      }
    },
    {
      for name, remediation in azurerm_resource_group_policy_remediation.resource_group : name => {
        id                   = remediation.id
        name                 = remediation.name
        scope                = remediation.resource_group_id
        scope_type           = "resource_group"
        policy_assignment_id = remediation.policy_assignment_id
      }
    },
    {
      for name, remediation in azurerm_management_group_policy_remediation.management_group : name => {
        id                   = remediation.id
        name                 = remediation.name
        scope                = remediation.management_group_id
        scope_type           = "management_group"
        policy_assignment_id = remediation.policy_assignment_id
      }
    }
  )
}
