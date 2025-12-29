output "profile_id" {
  description = "The ID of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "profile_name" {
  description = "The name of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "endpoint_host_names" {
  description = "Map of endpoint names to their host names"
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.host_name }
}

output "origin_group_ids" {
  description = "Map of origin group names to their IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_origin_group.this : k => v.id }
}

output "custom_domain_ids" {
  description = "Map of custom domain names to their IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.id }
}
