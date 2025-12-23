terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

resource "azurerm_virtual_network" "this" {
  for_each = var.virtual_networks

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  address_space       = each.value.address_space
  dns_servers         = each.value.dns_servers
  bgp_community       = each.value.bgp_community
  edge_zone           = each.value.edge_zone

  dynamic "ddos_protection_plan" {
    for_each = each.value.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = each.value.ddos_protection_plan_id
      enable = true
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption_enforcement != null ? [1] : []
    content {
      enforcement = each.value.encryption_enforcement
    }
  }

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                                          = each.key
  resource_group_name                           = each.value.resource_group_name
  virtual_network_name                          = each.value.virtual_network_name != null ? each.value.virtual_network_name : azurerm_virtual_network.this[each.value.virtual_network_key].name
  address_prefixes                              = each.value.address_prefixes
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoints                             = each.value.service_endpoints
  service_endpoint_policy_ids                   = each.value.service_endpoint_policy_ids

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.service_delegation_actions
      }
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = var.network_security_groups

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = var.network_security_rules

  name                                       = each.key
  priority                                   = each.value.priority
  direction                                  = each.value.direction
  access                                     = each.value.access
  protocol                                   = each.value.protocol
  source_port_range                          = each.value.source_port_range
  source_port_ranges                         = each.value.source_port_ranges
  destination_port_range                     = each.value.destination_port_range
  destination_port_ranges                    = each.value.destination_port_ranges
  source_address_prefix                      = each.value.source_address_prefix
  source_address_prefixes                    = each.value.source_address_prefixes
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  destination_address_prefix                 = each.value.destination_address_prefix
  destination_address_prefixes               = each.value.destination_address_prefixes
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
  resource_group_name                        = each.value.resource_group_name
  network_security_group_name                = each.value.network_security_group_name != null ? each.value.network_security_group_name : azurerm_network_security_group.this[each.value.network_security_group_key].name
  description                                = each.value.description
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnet_nsg_associations

  subnet_id                 = each.value.subnet_id != null ? each.value.subnet_id : azurerm_subnet.this[each.value.subnet_key].id
  network_security_group_id = each.value.network_security_group_id != null ? each.value.network_security_group_id : azurerm_network_security_group.this[each.value.network_security_group_key].id
}

resource "azurerm_application_security_group" "this" {
  for_each = var.application_security_groups

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_ddos_protection_plan" "this" {
  for_each = var.ddos_protection_plans

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = var.tags
}

resource "azurerm_public_ip" "this" {
  for_each = var.public_ips

  name                    = each.key
  location                = each.value.location
  resource_group_name     = each.value.resource_group_name
  allocation_method       = each.value.allocation_method
  sku                     = each.value.sku
  sku_tier                = each.value.sku_tier
  zones                   = each.value.zones
  ip_version              = each.value.ip_version
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  domain_name_label       = each.value.domain_name_label
  reverse_fqdn            = each.value.reverse_fqdn
  public_ip_prefix_id     = each.value.public_ip_prefix_id
  edge_zone               = each.value.edge_zone
  ddos_protection_mode    = each.value.ddos_protection_mode
  ddos_protection_plan_id = each.value.ddos_protection_plan_id
  tags                    = var.tags
}

resource "azurerm_public_ip_prefix" "this" {
  for_each = var.public_ip_prefixes

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  prefix_length       = each.value.prefix_length
  sku                 = each.value.sku
  zones               = each.value.zones
  ip_version          = each.value.ip_version
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  for_each = var.nat_gateways

  name                    = each.key
  location                = each.value.location
  resource_group_name     = each.value.resource_group_name
  sku_name                = each.value.sku_name
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  zones                   = each.value.zones
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  for_each = var.nat_gateway_public_ip_associations

  nat_gateway_id       = each.value.nat_gateway_id != null ? each.value.nat_gateway_id : azurerm_nat_gateway.this[each.value.nat_gateway_key].id
  public_ip_address_id = each.value.public_ip_address_id != null ? each.value.public_ip_address_id : azurerm_public_ip.this[each.value.public_ip_key].id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "this" {
  for_each = var.nat_gateway_public_ip_prefix_associations

  nat_gateway_id      = each.value.nat_gateway_id != null ? each.value.nat_gateway_id : azurerm_nat_gateway.this[each.value.nat_gateway_key].id
  public_ip_prefix_id = each.value.public_ip_prefix_id != null ? each.value.public_ip_prefix_id : azurerm_public_ip_prefix.this[each.value.public_ip_prefix_key].id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = var.subnet_nat_gateway_associations

  subnet_id      = each.value.subnet_id != null ? each.value.subnet_id : azurerm_subnet.this[each.value.subnet_key].id
  nat_gateway_id = each.value.nat_gateway_id != null ? each.value.nat_gateway_id : azurerm_nat_gateway.this[each.value.nat_gateway_key].id
}

resource "azurerm_route_table" "this" {
  for_each = var.route_tables

  name                          = each.key
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  tags                          = var.tags
}

resource "azurerm_route" "this" {
  for_each = var.routes

  name                   = each.key
  resource_group_name    = each.value.resource_group_name
  route_table_name       = each.value.route_table_name != null ? each.value.route_table_name : azurerm_route_table.this[each.value.route_table_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = var.subnet_route_table_associations

  subnet_id      = each.value.subnet_id != null ? each.value.subnet_id : azurerm_subnet.this[each.value.subnet_key].id
  route_table_id = each.value.route_table_id != null ? each.value.route_table_id : azurerm_route_table.this[each.value.route_table_key].id
}

resource "azurerm_network_watcher" "this" {
  for_each = var.network_watchers

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_watcher_flow_log" "this" {
  for_each = var.flow_logs

  name                      = each.key
  network_watcher_name      = each.value.network_watcher_name != null ? each.value.network_watcher_name : azurerm_network_watcher.this[each.value.network_watcher_key].name
  resource_group_name       = each.value.resource_group_name
  network_security_group_id = each.value.network_security_group_id != null ? each.value.network_security_group_id : azurerm_network_security_group.this[each.value.network_security_group_key].id
  storage_account_id        = each.value.storage_account_id
  enabled                   = each.value.enabled
  version                   = each.value.version

  retention_policy {
    enabled = each.value.retention_policy.enabled
    days    = each.value.retention_policy.days
  }

  dynamic "traffic_analytics" {
    for_each = each.value.traffic_analytics != null ? [each.value.traffic_analytics] : []
    content {
      enabled               = traffic_analytics.value.enabled
      workspace_id          = traffic_analytics.value.workspace_id
      workspace_region      = traffic_analytics.value.workspace_region
      workspace_resource_id = traffic_analytics.value.workspace_resource_id
      interval_in_minutes   = traffic_analytics.value.interval_in_minutes
    }
  }

  tags = var.tags
}

resource "azurerm_virtual_network_peering" "this" {
  for_each = var.virtual_network_peerings

  name                         = each.key
  resource_group_name          = each.value.resource_group_name
  virtual_network_name         = each.value.virtual_network_name != null ? each.value.virtual_network_name : azurerm_virtual_network.this[each.value.virtual_network_key].name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
  triggers                     = each.value.triggers
}

resource "azurerm_ip_group" "this" {
  for_each = var.ip_groups

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  cidrs               = each.value.cidrs
  tags                = var.tags
}

resource "azurerm_service_endpoint_policy" "this" {
  for_each = var.service_endpoint_policies

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = var.tags
}

resource "azurerm_service_endpoint_policy_definition" "this" {
  for_each = var.service_endpoint_policy_definitions

  name                       = each.key
  service_endpoint_policy_id = each.value.service_endpoint_policy_id != null ? each.value.service_endpoint_policy_id : azurerm_service_endpoint_policy.this[each.value.service_endpoint_policy_key].id
  service                    = each.value.service
  service_resources          = each.value.service_resources
  description                = each.value.description
}
