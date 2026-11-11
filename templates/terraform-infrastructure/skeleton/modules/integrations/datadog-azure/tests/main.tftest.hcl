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

mock_provider "datadog" {}

variables {
  name_prefix = "acme-dev"
  tags = {
    Project     = "acme"
    Environment = "development"
  }
}

run "connects_the_subscription" {
  command = plan

  assert {
    condition     = azuread_application.datadog.display_name == "acme-dev-datadog"
    error_message = "The app registration name must derive from name_prefix."
  }

  assert {
    condition     = azuread_application.datadog.sign_in_audience == "AzureADMyOrg"
    error_message = "The app registration must be limited to its own tenant."
  }

  assert {
    condition     = azurerm_role_assignment.monitoring_reader.role_definition_name == "Monitoring Reader"
    error_message = "Datadog must hold the read-only Monitoring Reader role."
  }

  assert {
    condition     = azurerm_role_assignment.monitoring_reader.scope == "/subscriptions/00000000-0000-0000-0000-000000000001"
    error_message = "The role must be assigned on the subscription of the azurerm provider."
  }

  assert {
    condition     = datadog_integration_azure.this.tenant_name == "00000000-0000-0000-0000-000000000002"
    error_message = "The integration must be registered for the tenant of the subscription."
  }

  assert {
    condition     = datadog_integration_azure.this.client_id == "00000000-0000-0000-0000-000000000005"
    error_message = "Datadog must sign in with the app registration created for it."
  }

  assert {
    condition     = azurerm_role_assignment.monitoring_reader.principal_id == "00000000-0000-0000-0000-000000000006"
    error_message = "The role must be assigned to the service principal of the app registration."
  }

  assert {
    condition     = datadog_integration_azure.this.metrics_enabled && !datadog_integration_azure.this.cspm_enabled
    error_message = "Metric collection must be on and posture management off."
  }

  assert {
    condition     = time_sleep.identity_propagation.create_duration == "60s"
    error_message = "The integration must wait for Entra ID replication."
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
    condition     = strcontains(azuread_application.datadog.notes, "Description=It's the team's \"main\" service: handles 50% of #1 & more")
    error_message = "Tag values must be recorded verbatim in the notes."
  }

  assert {
    condition     = length(azuread_application.datadog.notes) <= 1024
    error_message = "Notes must stay within the Entra ID limit."
  }
}

run "rejects_invalid_name_prefix" {
  command = plan

  variables {
    name_prefix = "Not_Valid"
  }

  expect_failures = [var.name_prefix]
}
