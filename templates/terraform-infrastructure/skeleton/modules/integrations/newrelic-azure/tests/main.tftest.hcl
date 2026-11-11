mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/00000000-0000-0000-0000-000000000001"
      subscription_id = "00000000-0000-0000-0000-000000000001"
      tenant_id       = "00000000-0000-0000-0000-000000000002"
    }
  }
}

mock_provider "azuread" {
  mock_data "azuread_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000003"
      tenant_id = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azuread_application" {
    override_during = plan
    defaults = {
      id        = "/applications/00000000-0000-0000-0000-000000000004"
      client_id = "00000000-0000-0000-0000-000000000005"
    }
  }

  mock_resource "azuread_service_principal" {
    override_during = plan
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000006"
    }
  }
}

mock_provider "time" {}

mock_provider "newrelic" {}

variables {
  name_prefix = "acme-dev"
  tags = {
    Project     = "acme"
    Environment = "development"
  }
}

run "links_the_subscription" {
  command = plan

  assert {
    condition     = azuread_application.newrelic.display_name == "acme-dev-newrelic"
    error_message = "The app registration name must derive from name_prefix."
  }

  assert {
    condition     = azuread_application.newrelic.sign_in_audience == "AzureADMyOrg"
    error_message = "The app registration must be limited to its own tenant."
  }

  assert {
    condition     = toset(keys(azurerm_role_assignment.newrelic)) == toset(["Reader", "Monitoring Reader"])
    error_message = "New Relic must hold exactly the two read-only roles it documents."
  }

  assert {
    condition = alltrue([
      for assignment in azurerm_role_assignment.newrelic :
      assignment.scope == "/subscriptions/00000000-0000-0000-0000-000000000001"
    ])
    error_message = "The roles must be assigned on the subscription of the azurerm provider."
  }

  assert {
    condition     = nonsensitive(newrelic_cloud_azure_link_account.this.subscription_id) == "00000000-0000-0000-0000-000000000001" && nonsensitive(newrelic_cloud_azure_link_account.this.tenant_id) == "00000000-0000-0000-0000-000000000002"
    error_message = "The link must target the subscription and tenant of the azurerm provider."
  }

  assert {
    condition     = nonsensitive(newrelic_cloud_azure_link_account.this.application_id) == "00000000-0000-0000-0000-000000000005"
    error_message = "New Relic must sign in with the app registration created for it."
  }

  assert {
    condition = alltrue([
      for integration in ["virtual_networks", "load_balancer", "app_gateway", "front_door", "containers", "vms", "postgresql", "postgresql_flexible", "mysql", "mysql_flexible", "cosmos_db", "redis_cache", "storage", "key_vault"] :
      length(newrelic_cloud_azure_integrations.this[integration]) == 1
    ])
    error_message = "Every service the stack can create must have its integration enabled."
  }
}

run "links_an_explicit_account" {
  command = plan

  variables {
    newrelic_account_id = 1234567
  }

  assert {
    condition     = newrelic_cloud_azure_link_account.this.account_id == 1234567 && newrelic_cloud_azure_integrations.this.account_id == 1234567
    error_message = "The link and the integrations must target the given account."
  }
}

run "records_tags_in_notes" {
  command = plan

  variables {
    tags = {
      Description = "It's the team's \"main\" service: handles 50% of #1 & more"
    }
  }

  assert {
    condition     = strcontains(azuread_application.newrelic.notes, "Description=It's the team's \"main\" service: handles 50% of #1 & more")
    error_message = "Tag values must be recorded verbatim in the notes."
  }
}

run "rejects_invalid_name_prefix" {
  command = plan

  variables {
    name_prefix = "Not_Valid"
  }

  expect_failures = [var.name_prefix]
}
