output "network_manager_ids" {
  value = { for k, v in azurerm_network_manager.this : k => v.id }
}

output "network_manager_cross_tenant_scopes" {
  value = { for k, v in azurerm_network_manager.this : k => v.cross_tenant_scopes }
}

output "network_group_ids" {
  value = { for k, v in azurerm_network_manager_network_group.this : k => v.id }
}

output "static_member_ids" {
  value = { for k, v in azurerm_network_manager_static_member.this : k => v.id }
}

output "connectivity_configuration_ids" {
  value = { for k, v in azurerm_network_manager_connectivity_configuration.this : k => v.id }
}

output "security_admin_configuration_ids" {
  value = { for k, v in azurerm_network_manager_security_admin_configuration.this : k => v.id }
}

output "admin_rule_collection_ids" {
  value = { for k, v in azurerm_network_manager_admin_rule_collection.this : k => v.id }
}

output "admin_rule_ids" {
  value = { for k, v in azurerm_network_manager_admin_rule.this : k => v.id }
}
