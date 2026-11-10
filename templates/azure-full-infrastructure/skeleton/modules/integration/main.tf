# =============================================================================
# Integration Module
# =============================================================================
# Service Bus namespace and an Event Grid topic. Both accept Entra ID
# identities only; shared access keys are switched off.
# =============================================================================

locals {
  prefix = "${var.name}-${var.environment}"

  premium_service_bus = var.service_bus_sku == "Premium"
}

resource "azurerm_servicebus_namespace" "main" {
  #checkov:skip=CKV_AZURE_201:Messages are encrypted with platform-managed keys; a customer-managed key needs the Premium SKU and a Key Vault
  #checkov:skip=CKV_AZURE_199:Infrastructure (double) encryption is configured together with a customer-managed key
  #checkov:skip=CKV_AZURE_204:Publishers and subscribers outside the virtual network reach the namespace over its public endpoint; access needs an Entra ID role
  name                = "sb-${local.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.service_bus_sku
  capacity            = local.premium_service_bus ? 1 : 0
  zone_redundant      = local.premium_service_bus && var.enable_high_availability

  local_auth_enabled            = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_eventgrid_topic" "main" {
  #checkov:skip=CKV_AZURE_193:Publishers outside the virtual network reach the topic over its public endpoint; access needs an Entra ID role
  name                = "evgt-${local.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  local_auth_enabled            = false
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
