data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

locals {
  # Entra ID limits notes to 1,024 characters.
  notes = substr(join("; ", concat(
    ["Datadog reads Azure Monitor metrics of subscription ${data.azurerm_subscription.current.subscription_id} with this identity. Managed by Terraform."],
    [for key, value in var.tags : "${key}=${value}"],
  )), 0, 1024)
}

# App registration Datadog signs in with.
resource "azuread_application" "datadog" {
  display_name     = "${var.name_prefix}-datadog"
  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current.object_id]
  notes            = local.notes
}

resource "azuread_service_principal" "datadog" {
  client_id = azuread_application.datadog.client_id
  owners    = [data.azuread_client_config.current.object_id]
  notes     = local.notes
}

# The client secret is replaced by the first apply after a year, well before
# Entra ID expires it.
resource "time_rotating" "client_secret" {
  rotation_days = 365
}

resource "azuread_application_password" "datadog" {
  application_id = azuread_application.datadog.id
  display_name   = "datadog-integration"

  rotate_when_changed = {
    rotation = time_rotating.client_secret.id
  }
}

# Monitoring Reader is the read-only role Datadog documents for metric collection.
resource "azurerm_role_assignment" "monitoring_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azuread_service_principal.datadog.object_id
  principal_type       = "ServicePrincipal"
}

# Entra ID replicates new secrets and role assignments asynchronously, and
# Datadog signs in with them as soon as the integration is saved.
resource "time_sleep" "identity_propagation" {
  create_duration = "60s"

  triggers = {
    client_secret   = azuread_application_password.datadog.key_id
    role_assignment = azurerm_role_assignment.monitoring_reader.id
  }
}
