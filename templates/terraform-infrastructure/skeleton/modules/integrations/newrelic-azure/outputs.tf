output "linked_account_id" {
  description = "ID of the linked Azure subscription in New Relic."
  value       = newrelic_cloud_azure_link_account.this.id
}

output "application_client_id" {
  description = "Client ID of the app registration New Relic signs in with."
  value       = azuread_application.newrelic.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the service principal that holds the Reader and Monitoring Reader roles."
  value       = azuread_service_principal.newrelic.object_id
}
