terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

resource "azurerm_network_manager" "this" {
  for_each = var.network_managers

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  description         = each.value.description
  scope_accesses      = each.value.scope_accesses

  scope {
    management_group_ids = each.value.scope.management_group_ids
    subscription_ids     = each.value.scope.subscription_ids
  }

  tags = var.tags
}

resource "azurerm_network_manager_network_group" "this" {
  for_each = var.network_groups

  name               = each.key
  network_manager_id = each.value.network_manager_id != null ? each.value.network_manager_id : azurerm_network_manager.this[each.value.network_manager_key].id
  description        = each.value.description
}

resource "azurerm_network_manager_static_member" "this" {
  for_each = var.static_members

  name                      = each.key
  network_group_id          = each.value.network_group_id != null ? each.value.network_group_id : azurerm_network_manager_network_group.this[each.value.network_group_key].id
  target_virtual_network_id = each.value.target_virtual_network_id
}

resource "azurerm_network_manager_connectivity_configuration" "this" {
  for_each = var.connectivity_configurations

  name                  = each.key
  network_manager_id    = each.value.network_manager_id != null ? each.value.network_manager_id : azurerm_network_manager.this[each.value.network_manager_key].id
  connectivity_topology = each.value.connectivity_topology
  description           = each.value.description
  global_mesh_enabled   = each.value.global_mesh_enabled

  dynamic "applies_to_group" {
    for_each = each.value.applies_to_groups
    content {
      group_connectivity  = applies_to_group.value.group_connectivity
      network_group_id    = applies_to_group.value.network_group_id != null ? applies_to_group.value.network_group_id : azurerm_network_manager_network_group.this[applies_to_group.value.network_group_key].id
      global_mesh_enabled = applies_to_group.value.global_mesh_enabled
      use_hub_gateway     = applies_to_group.value.use_hub_gateway
    }
  }

  dynamic "hub" {
    for_each = each.value.hub != null ? [each.value.hub] : []
    content {
      resource_id   = hub.value.resource_id
      resource_type = hub.value.resource_type
    }
  }
}

resource "azurerm_network_manager_security_admin_configuration" "this" {
  for_each = var.security_admin_configurations

  name                                          = each.key
  network_manager_id                            = each.value.network_manager_id != null ? each.value.network_manager_id : azurerm_network_manager.this[each.value.network_manager_key].id
  description                                   = each.value.description
  apply_on_network_intent_policy_based_services = each.value.apply_on_network_intent_policy_based_services
}

resource "azurerm_network_manager_admin_rule_collection" "this" {
  for_each = var.admin_rule_collections

  name                            = each.key
  security_admin_configuration_id = each.value.security_admin_configuration_id != null ? each.value.security_admin_configuration_id : azurerm_network_manager_security_admin_configuration.this[each.value.security_admin_configuration_key].id
  description                     = each.value.description
  network_group_ids = [
    for k in each.value.network_group_keys : azurerm_network_manager_network_group.this[k].id
  ]
}

resource "azurerm_network_manager_admin_rule" "this" {
  for_each = var.admin_rules

  name                     = each.key
  admin_rule_collection_id = each.value.admin_rule_collection_id != null ? each.value.admin_rule_collection_id : azurerm_network_manager_admin_rule_collection.this[each.value.admin_rule_collection_key].id
  action                   = each.value.action
  direction                = each.value.direction
  priority                 = each.value.priority
  protocol                 = each.value.protocol
  description              = each.value.description
  source_port_ranges       = each.value.source_port_ranges
  destination_port_ranges  = each.value.destination_port_ranges

  dynamic "source" {
    for_each = each.value.sources
    content {
      address_prefix_type = source.value.address_prefix_type
      address_prefix      = source.value.address_prefix
    }
  }

  dynamic "destination" {
    for_each = each.value.destinations
    content {
      address_prefix_type = destination.value.address_prefix_type
      address_prefix      = destination.value.address_prefix
    }
  }
}

resource "azurerm_network_manager_deployment" "connectivity" {
  for_each = var.connectivity_deployments

  network_manager_id = each.value.network_manager_id != null ? each.value.network_manager_id : azurerm_network_manager.this[each.value.network_manager_key].id
  location           = each.value.location
  scope_access       = "Connectivity"
  configuration_ids  = each.value.configuration_ids != null ? each.value.configuration_ids : [for k in each.value.configuration_keys : azurerm_network_manager_connectivity_configuration.this[k].id]

  triggers = {
    configuration_ids = join(",", each.value.configuration_ids != null ? each.value.configuration_ids : [for k in each.value.configuration_keys : azurerm_network_manager_connectivity_configuration.this[k].id])
  }
}

resource "azurerm_network_manager_deployment" "security_admin" {
  for_each = var.security_admin_deployments

  network_manager_id = each.value.network_manager_id != null ? each.value.network_manager_id : azurerm_network_manager.this[each.value.network_manager_key].id
  location           = each.value.location
  scope_access       = "SecurityAdmin"
  configuration_ids  = each.value.configuration_ids != null ? each.value.configuration_ids : [for k in each.value.configuration_keys : azurerm_network_manager_security_admin_configuration.this[k].id]

  triggers = {
    configuration_ids = join(",", each.value.configuration_ids != null ? each.value.configuration_ids : [for k in each.value.configuration_keys : azurerm_network_manager_security_admin_configuration.this[k].id])
  }
}
