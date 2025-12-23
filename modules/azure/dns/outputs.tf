output "public_dns_zone_ids" {
  value = { for k, v in azurerm_dns_zone.this : k => v.id }
}

output "public_dns_zone_name_servers" {
  value = { for k, v in azurerm_dns_zone.this : k => v.name_servers }
}

output "private_dns_zone_ids" {
  value = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}

output "private_dns_zone_names" {
  value = { for k, v in azurerm_private_dns_zone.this : k => v.name }
}

output "traffic_manager_profile_ids" {
  value = { for k, v in azurerm_traffic_manager_profile.this : k => v.id }
}

output "traffic_manager_profile_fqdns" {
  value = { for k, v in azurerm_traffic_manager_profile.this : k => v.fqdn }
}

output "frontdoor_profile_ids" {
  value = { for k, v in azurerm_cdn_frontdoor_profile.this : k => v.id }
}

output "frontdoor_profile_resource_guids" {
  value = { for k, v in azurerm_cdn_frontdoor_profile.this : k => v.resource_guid }
}

output "frontdoor_endpoint_ids" {
  value = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.id }
}

output "frontdoor_endpoint_host_names" {
  value = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.host_name }
}

output "frontdoor_origin_group_ids" {
  value = { for k, v in azurerm_cdn_frontdoor_origin_group.this : k => v.id }
}

output "frontdoor_origin_ids" {
  value = { for k, v in azurerm_cdn_frontdoor_origin.this : k => v.id }
}

output "frontdoor_route_ids" {
  value = { for k, v in azurerm_cdn_frontdoor_route.this : k => v.id }
}

output "frontdoor_custom_domain_ids" {
  value = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.id }
}

output "frontdoor_waf_policy_ids" {
  value = { for k, v in azurerm_cdn_frontdoor_firewall_policy.this : k => v.id }
}

output "frontdoor_security_policy_ids" {
  value = { for k, v in azurerm_cdn_frontdoor_security_policy.this : k => v.id }
}
