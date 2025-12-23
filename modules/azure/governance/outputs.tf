output "management_group_ids" {
  value = { for k, v in azurerm_management_group.this : k => v.id }
}

output "management_group_names" {
  value = { for k, v in azurerm_management_group.this : k => v.name }
}

output "policy_definition_ids" {
  value = { for k, v in azurerm_policy_definition.this : k => v.id }
}

output "policy_set_definition_ids" {
  value = { for k, v in azurerm_policy_set_definition.this : k => v.id }
}

output "management_group_policy_assignment_ids" {
  value = { for k, v in azurerm_management_group_policy_assignment.this : k => v.id }
}

output "management_group_policy_assignment_identities" {
  value = { for k, v in azurerm_management_group_policy_assignment.this : k => v.identity }
}

output "subscription_policy_assignment_ids" {
  value = { for k, v in azurerm_subscription_policy_assignment.this : k => v.id }
}

output "subscription_policy_assignment_identities" {
  value = { for k, v in azurerm_subscription_policy_assignment.this : k => v.identity }
}

output "resource_group_policy_assignment_ids" {
  value = { for k, v in azurerm_resource_group_policy_assignment.this : k => v.id }
}

output "resource_group_policy_assignment_identities" {
  value = { for k, v in azurerm_resource_group_policy_assignment.this : k => v.identity }
}

output "management_group_remediation_ids" {
  value = { for k, v in azurerm_policy_remediation.management_group : k => v.id }
}

output "subscription_remediation_ids" {
  value = { for k, v in azurerm_policy_remediation.subscription : k => v.id }
}

output "resource_group_remediation_ids" {
  value = { for k, v in azurerm_policy_remediation.resource_group : k => v.id }
}

output "subscription_association_ids" {
  value = { for k, v in azurerm_management_group_subscription_association.this : k => v.id }
}
