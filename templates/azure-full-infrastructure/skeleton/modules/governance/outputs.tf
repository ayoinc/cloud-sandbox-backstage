output "budget_id" {
  description = "Budget ID"
  value       = azurerm_consumption_budget_resource_group.main.id
}

output "tag_policy_assignment_ids" {
  description = "Tag policy assignment IDs keyed by tag name"
  value       = { for tag, assignment in azurerm_resource_group_policy_assignment.require_tag : tag => assignment.id }
}
