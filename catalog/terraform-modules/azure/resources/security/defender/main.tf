terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

resource "azurerm_security_center_subscription_pricing" "defender" {
  for_each = var.resource_type_pricing

  tier          = each.value.tier
  resource_type = each.key
  subplan       = each.value.subplan
}

resource "azurerm_security_center_contact" "contact" {
  email               = var.security_contact_email
  phone               = var.security_contact_phone
  alert_notifications = var.alert_notifications
  alerts_to_admins    = var.alerts_to_admins
}

resource "azurerm_security_center_auto_provisioning" "auto_provisioning" {
  auto_provision = var.auto_provisioning
}

resource "azurerm_security_center_setting" "mcas" {
  count = var.enable_mcas_integration ? 1 : 0

  setting_name = "MCAS"
  enabled      = true
}

resource "azurerm_security_center_setting" "wdatp" {
  count = var.enable_wdatp_integration ? 1 : 0

  setting_name = "WDATP"
  enabled      = true
}

resource "azurerm_security_center_workspace" "workspace" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = var.log_analytics_workspace_id
}

data "azurerm_client_config" "current" {}
