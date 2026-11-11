data "azurerm_client_config" "current" {}

locals {
  tags = merge(
    {
      Service     = var.service_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  # The classic tiers always host a developer portal. With the portal switched
  # off, visitors are sent to the sign-in page and cannot register.
  portal_sign_in_required = var.enable_portal_auth || !var.enable_portal
}

# Named rg-<service_name>-<environment>-<location> by the module.
module "resource_group" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/core/resource-group?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  name        = var.service_name
  project     = var.service_name
  environment = var.environment
  location    = var.location
  tags        = var.tags
}

resource "azurerm_api_management" "this" {
  name                = var.service_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "${var.sku}_${var.sku_capacity}"
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }

  sign_in {
    enabled = local.portal_sign_in_required
  }

  sign_up {
    enabled = var.enable_portal

    terms_of_service {
      enabled          = false
      consent_required = false
    }
  }
}
