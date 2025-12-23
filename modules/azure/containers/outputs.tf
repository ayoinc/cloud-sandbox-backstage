output "acr_ids" {
  value = { for k, v in azurerm_container_registry.this : k => v.id }
}

output "acr_login_servers" {
  value = { for k, v in azurerm_container_registry.this : k => v.login_server }
}

output "acr_admin_usernames" {
  value     = { for k, v in azurerm_container_registry.this : k => v.admin_username }
  sensitive = true
}

output "acr_admin_passwords" {
  value     = { for k, v in azurerm_container_registry.this : k => v.admin_password }
  sensitive = true
}

output "acr_identities" {
  value = { for k, v in azurerm_container_registry.this : k => try(v.identity[0].principal_id, null) }
}

output "acr_scope_map_ids" {
  value = { for k, v in azurerm_container_registry_scope_map.this : k => v.id }
}

output "acr_token_ids" {
  value = { for k, v in azurerm_container_registry_token.this : k => v.id }
}

output "acr_private_endpoint_ips" {
  value = { for k, v in azurerm_private_endpoint.acr : k => v.private_service_connection[0].private_ip_address }
}

output "container_group_ids" {
  value = { for k, v in azurerm_container_group.this : k => v.id }
}

output "container_group_ips" {
  value = { for k, v in azurerm_container_group.this : k => v.ip_address }
}

output "container_group_fqdns" {
  value = { for k, v in azurerm_container_group.this : k => v.fqdn }
}
