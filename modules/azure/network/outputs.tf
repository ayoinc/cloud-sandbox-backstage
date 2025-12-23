output "virtual_network_ids" {
  value = { for k, v in azurerm_virtual_network.this : k => v.id }
}

output "virtual_network_names" {
  value = { for k, v in azurerm_virtual_network.this : k => v.name }
}

output "virtual_network_address_spaces" {
  value = { for k, v in azurerm_virtual_network.this : k => v.address_space }
}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  value = { for k, v in azurerm_subnet.this : k => v.address_prefixes }
}

output "network_security_group_ids" {
  value = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "application_security_group_ids" {
  value = { for k, v in azurerm_application_security_group.this : k => v.id }
}

output "ddos_protection_plan_ids" {
  value = { for k, v in azurerm_network_ddos_protection_plan.this : k => v.id }
}

output "public_ip_ids" {
  value = { for k, v in azurerm_public_ip.this : k => v.id }
}

output "public_ip_addresses" {
  value = { for k, v in azurerm_public_ip.this : k => v.ip_address }
}

output "public_ip_prefix_ids" {
  value = { for k, v in azurerm_public_ip_prefix.this : k => v.id }
}

output "nat_gateway_ids" {
  value = { for k, v in azurerm_nat_gateway.this : k => v.id }
}

output "route_table_ids" {
  value = { for k, v in azurerm_route_table.this : k => v.id }
}

output "network_watcher_ids" {
  value = { for k, v in azurerm_network_watcher.this : k => v.id }
}

output "flow_log_ids" {
  value = { for k, v in azurerm_network_watcher_flow_log.this : k => v.id }
}

output "ip_group_ids" {
  value = { for k, v in azurerm_ip_group.this : k => v.id }
}

output "service_endpoint_policy_ids" {
  value = { for k, v in azurerm_service_endpoint_policy.this : k => v.id }
}
