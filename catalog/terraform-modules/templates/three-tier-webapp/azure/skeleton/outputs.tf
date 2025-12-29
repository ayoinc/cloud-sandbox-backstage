output "resource_group_name" {
  value = module.resource_group.name
}

output "vnet_id" {
  value = module.virtual_network.vnet_id
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}
