output "pricing_ids" {
  description = "Map of resource types to their Defender pricing resource IDs"
  value       = { for k, v in azurerm_security_center_subscription_pricing.defender : k => v.id }
}

output "security_contact_id" {
  description = "ID of the security center contact"
  value       = azurerm_security_center_contact.contact.id
}

output "auto_provisioning_id" {
  description = "ID of the auto provisioning configuration"
  value       = azurerm_security_center_auto_provisioning.auto_provisioning.id
}
