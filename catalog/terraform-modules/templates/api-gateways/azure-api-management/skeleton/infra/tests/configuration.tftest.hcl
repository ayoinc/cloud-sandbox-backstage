# Plans the configuration with the committed variable values against mocked
# providers. No Azure credentials are used and nothing is created.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  # The global policy refers to these attributes, so they get values while
  # planning instead of staying unknown.
  mock_resource "azurerm_api_management" {
    override_during = plan

    defaults = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ApiManagement/service/mock"
      gateway_url          = "https://mock.azure-api.net"
      developer_portal_url = "https://mock.developer.azure-api.net"
    }
  }
}

mock_provider "azuread" {
  mock_data "azuread_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

run "committed_values" {
  command = plan

  assert {
    condition     = azurerm_api_management.this.sku_name == "${var.sku}_${var.sku_capacity}"
    error_message = "The instance does not use the configured tier."
  }

  assert {
    condition = (
      startswith(azurerm_api_management_policy.global.xml_content, "<policies>") &&
      endswith(azurerm_api_management_policy.global.xml_content, "</policies>") &&
      length(regexall("<cors ", azurerm_api_management_policy.global.xml_content)) == (var.enable_cors ? 1 : 0) &&
      length(regexall("</cors>", azurerm_api_management_policy.global.xml_content)) == (var.enable_cors ? 1 : 0) &&
      length(regexall("<validate-jwt ", azurerm_api_management_policy.global.xml_content)) == (var.enable_jwt ? 1 : 0) &&
      length(regexall("</validate-jwt>", azurerm_api_management_policy.global.xml_content)) == (var.enable_jwt ? 1 : 0) &&
      length(regexall("<cache-lookup ", azurerm_api_management_policy.global.xml_content)) == (var.enable_caching ? 1 : 0) &&
      length(regexall("</cache-lookup>", azurerm_api_management_policy.global.xml_content)) == (var.enable_caching ? 1 : 0) &&
      length(regexall("<cache-store ", azurerm_api_management_policy.global.xml_content)) == (var.enable_caching ? 1 : 0)
    )
    error_message = "The global policy does not contain exactly the enabled policies."
  }

  assert {
    condition     = length(azurerm_api_management_product_policy.rate_limit) == (var.enable_rate_limiting ? 1 : 0)
    error_message = "The product policy with the rate limit does not follow enable_rate_limiting."
  }

  assert {
    condition = (
      length(azurerm_api_management_api.this) == length(var.apis) &&
      length(azurerm_api_management_product_api.this) == length(var.apis)
    )
    error_message = "Every entry of apis must become one API that belongs to the product."
  }

  assert {
    condition     = length(azurerm_api_management_identity_provider_aad.this) == (var.enable_portal && var.enable_azure_ad && var.sku != "Basic" ? 1 : 0)
    error_message = "The Microsoft Entra ID identity provider must exist only with the portal enabled outside the Basic tier."
  }

  assert {
    condition     = length(module.diagnostic_settings) == (var.enable_log_analytics ? 1 : 0) && length(azurerm_api_management_logger.application_insights) == (var.enable_application_insights ? 1 : 0)
    error_message = "Monitoring resources do not follow the monitoring switches."
  }
}
