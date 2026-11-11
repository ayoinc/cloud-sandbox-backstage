locals {
  # Microsoft Entra ID sign-in on the developer portal is not offered in the
  # Basic tier, so the identity provider is left out there.
  portal_entra_enabled = var.enable_portal && var.enable_azure_ad && var.sku != "Basic"

  microsoft_graph_app_id    = "00000003-0000-0000-c000-000000000000"
  microsoft_graph_user_read = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
}

data "azuread_client_config" "current" {
  count = local.portal_entra_enabled ? 1 : 0
}

# App registration the developer portal signs users in with.
resource "azuread_application" "portal" {
  count = local.portal_entra_enabled ? 1 : 0

  display_name     = "${var.service_name}-developer-portal"
  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current[0].object_id]

  single_page_application {
    redirect_uris = ["${azurerm_api_management.this.developer_portal_url}/signin"]
  }

  required_resource_access {
    resource_app_id = local.microsoft_graph_app_id

    resource_access {
      id   = local.microsoft_graph_user_read
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "portal" {
  count = local.portal_entra_enabled ? 1 : 0

  client_id = azuread_application.portal[0].client_id
  owners    = [data.azuread_client_config.current[0].object_id]
}

resource "azuread_application_password" "portal" {
  count = local.portal_entra_enabled ? 1 : 0

  application_id = azuread_application.portal[0].id
  display_name   = "API Management developer portal"
}

resource "azurerm_api_management_identity_provider_aad" "this" {
  count = local.portal_entra_enabled ? 1 : 0

  api_management_name = azurerm_api_management.this.name
  resource_group_name = module.resource_group.name
  client_id           = azuread_application.portal[0].client_id
  client_secret       = azuread_application_password.portal[0].value
  client_library      = "MSAL-2"
  allowed_tenants     = [data.azurerm_client_config.current.tenant_id]
  signin_tenant       = data.azurerm_client_config.current.tenant_id

  depends_on = [azuread_service_principal.portal]
}
