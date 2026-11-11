# Connects the tenant to Datadog. Datadog discovers every subscription the
# service principal can read, which is the subscription of the azurerm provider.
resource "datadog_integration_azure" "this" {
  tenant_name   = data.azurerm_subscription.current.tenant_id
  client_id     = azuread_application.datadog.client_id
  client_secret = azuread_application_password.datadog.value

  metrics_enabled        = true
  custom_metrics_enabled = false
  automute               = true
  cspm_enabled           = false

  depends_on = [time_sleep.identity_propagation]
}
