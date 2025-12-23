output "firewall_ids" {
  value = { for k, v in azurerm_firewall.this : k => v.id }
}

output "firewall_private_ips" {
  value = { for k, v in azurerm_firewall.this : k => v.ip_configuration[0].private_ip_address }
}

output "firewall_public_ips" {
  value = { for k, v in azurerm_public_ip.firewall : k => v.ip_address }
}

output "firewall_policy_ids" {
  value = { for k, v in azurerm_firewall_policy.this : k => v.id }
}

output "vpn_gateway_ids" {
  value = { for k, v in azurerm_virtual_network_gateway.vpn : k => v.id }
}

output "vpn_gateway_public_ips" {
  value = { for k, v in azurerm_public_ip.vpn_gateway : k => v.ip_address }
}

output "vpn_gateway_bgp_settings" {
  value = { for k, v in azurerm_virtual_network_gateway.vpn : k => v.bgp_settings }
}

output "expressroute_gateway_ids" {
  value = { for k, v in azurerm_virtual_network_gateway.expressroute : k => v.id }
}

output "expressroute_gateway_public_ips" {
  value = { for k, v in azurerm_public_ip.expressroute : k => v.ip_address }
}

output "local_network_gateway_ids" {
  value = { for k, v in azurerm_local_network_gateway.this : k => v.id }
}

output "gateway_connection_ids" {
  value = { for k, v in azurerm_virtual_network_gateway_connection.this : k => v.id }
}

output "bastion_ids" {
  value = { for k, v in azurerm_bastion_host.this : k => v.id }
}

output "bastion_dns_names" {
  value = { for k, v in azurerm_bastion_host.this : k => v.dns_name }
}

output "expressroute_circuit_ids" {
  value = { for k, v in azurerm_express_route_circuit.this : k => v.id }
}

output "expressroute_circuit_service_keys" {
  value     = { for k, v in azurerm_express_route_circuit.this : k => v.service_key }
  sensitive = true
}

output "route_filter_ids" {
  value = { for k, v in azurerm_route_filter.this : k => v.id }
}
