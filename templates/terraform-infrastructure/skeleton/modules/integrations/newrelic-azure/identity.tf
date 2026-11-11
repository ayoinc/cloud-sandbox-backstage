data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

locals {
  # Entra ID limits notes to 1,024 characters.
  notes = substr(join("; ", concat(
    ["New Relic reads Azure Monitor metrics and resource metadata of subscription ${data.azurerm_subscription.current.subscription_id} with this identity. Managed by Terraform."],
    [for key, value in var.tags : "${key}=${value}"],
  )), 0, 1024)

  # Reader lists the resources to monitor; Monitoring Reader lets New Relic
  # use the Azure Monitor metrics batch API.
  roles = toset(["Reader", "Monitoring Reader"])
}

# App registration New Relic signs in with.
resource "azuread_application" "newrelic" {
  display_name     = "${var.name_prefix}-newrelic"
  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current.object_id]
  notes            = local.notes

  web {
    redirect_uris = ["https://www.newrelic.com/"]
  }
}

resource "azuread_service_principal" "newrelic" {
  client_id = azuread_application.newrelic.client_id
  owners    = [data.azuread_client_config.current.object_id]
  notes     = local.notes
}

# The client secret is replaced by the first apply after a year, well before
# Entra ID expires it.
resource "time_rotating" "client_secret" {
  rotation_days = 365
}

resource "azuread_application_password" "newrelic" {
  application_id = azuread_application.newrelic.id
  display_name   = "newrelic-integration"

  rotate_when_changed = {
    rotation = time_rotating.client_secret.id
  }
}

resource "azurerm_role_assignment" "newrelic" {
  for_each = local.roles

  scope                = data.azurerm_subscription.current.id
  role_definition_name = each.value
  principal_id         = azuread_service_principal.newrelic.object_id
  principal_type       = "ServicePrincipal"
}

# Entra ID replicates new secrets and role assignments asynchronously, and
# New Relic signs in with them as soon as the subscription is linked.
resource "time_sleep" "identity_propagation" {
  create_duration = "60s"

  triggers = {
    client_secret    = azuread_application_password.newrelic.key_id
    role_assignments = join(",", [for role in sort(local.roles) : azurerm_role_assignment.newrelic[role].id])
  }
}
