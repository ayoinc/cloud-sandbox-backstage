output "integration_id" {
  description = "ID of the Azure integration in Datadog (tenant ID and client ID)."
  value       = datadog_integration_azure.this.id
}

output "application_client_id" {
  description = "Client ID of the app registration Datadog signs in with."
  value       = azuread_application.datadog.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the service principal that holds the Monitoring Reader role."
  value       = azuread_service_principal.datadog.object_id
}
