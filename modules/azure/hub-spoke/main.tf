terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

resource "azurerm_public_ip" "firewall" {
  for_each = var.firewalls

  name                = "${each.key}-pip"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zones
  tags                = var.tags
}

resource "azurerm_public_ip" "firewall_management" {
  for_each = { for k, v in var.firewalls : k => v if v.management_subnet_id != null }

  name                = "${each.key}-mgmt-pip"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zones
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  for_each = var.firewall_policies

  name                              = each.key
  resource_group_name               = each.value.resource_group_name
  location                          = each.value.location
  sku                               = each.value.sku
  threat_intelligence_mode          = each.value.threat_intelligence_mode
  sql_redirect_allowed              = each.value.sql_redirect_allowed
  private_ip_ranges                 = each.value.private_ip_ranges
  auto_learn_private_ranges_enabled = each.value.auto_learn_private_ranges_enabled

  dynamic "dns" {
    for_each = each.value.dns != null ? [each.value.dns] : []
    content {
      proxy_enabled = dns.value.proxy_enabled
      servers       = dns.value.servers
    }
  }

  dynamic "intrusion_detection" {
    for_each = each.value.intrusion_detection != null ? [each.value.intrusion_detection] : []
    content {
      mode = intrusion_detection.value.mode
      dynamic "signature_overrides" {
        for_each = intrusion_detection.value.signature_overrides != null ? intrusion_detection.value.signature_overrides : []
        content {
          id    = signature_overrides.value.id
          state = signature_overrides.value.state
        }
      }
      dynamic "traffic_bypass" {
        for_each = intrusion_detection.value.traffic_bypass != null ? intrusion_detection.value.traffic_bypass : []
        content {
          name                  = traffic_bypass.value.name
          protocol              = traffic_bypass.value.protocol
          destination_addresses = traffic_bypass.value.destination_addresses
          destination_ip_groups = traffic_bypass.value.destination_ip_groups
          destination_ports     = traffic_bypass.value.destination_ports
          source_addresses      = traffic_bypass.value.source_addresses
          source_ip_groups      = traffic_bypass.value.source_ip_groups
        }
      }
    }
  }

  dynamic "threat_intelligence_allowlist" {
    for_each = each.value.threat_intelligence_allowlist != null ? [each.value.threat_intelligence_allowlist] : []
    content {
      fqdns        = threat_intelligence_allowlist.value.fqdns
      ip_addresses = threat_intelligence_allowlist.value.ip_addresses
    }
  }

  dynamic "tls_certificate" {
    for_each = each.value.tls_certificate != null ? [each.value.tls_certificate] : []
    content {
      key_vault_secret_id = tls_certificate.value.key_vault_secret_id
      name                = tls_certificate.value.name
    }
  }

  dynamic "explicit_proxy" {
    for_each = each.value.explicit_proxy != null ? [each.value.explicit_proxy] : []
    content {
      enabled         = explicit_proxy.value.enabled
      http_port       = explicit_proxy.value.http_port
      https_port      = explicit_proxy.value.https_port
      enable_pac_file = explicit_proxy.value.enable_pac_file
      pac_file_port   = explicit_proxy.value.pac_file_port
      pac_file        = explicit_proxy.value.pac_file
    }
  }

  tags = var.tags
}

resource "azurerm_firewall" "this" {
  for_each = var.firewalls

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku_name            = each.value.sku_name
  sku_tier            = each.value.sku_tier
  firewall_policy_id  = each.value.firewall_policy_id != null ? each.value.firewall_policy_id : (each.value.firewall_policy_key != null ? azurerm_firewall_policy.this[each.value.firewall_policy_key].id : null)
  zones               = each.value.zones
  threat_intel_mode   = each.value.threat_intel_mode
  dns_proxy_enabled   = each.value.dns_proxy_enabled
  dns_servers         = each.value.dns_servers

  ip_configuration {
    name                 = "configuration"
    subnet_id            = each.value.subnet_id
    public_ip_address_id = azurerm_public_ip.firewall[each.key].id
  }

  dynamic "management_ip_configuration" {
    for_each = each.value.management_subnet_id != null ? [1] : []
    content {
      name                 = "management"
      subnet_id            = each.value.management_subnet_id
      public_ip_address_id = azurerm_public_ip.firewall_management[each.key].id
    }
  }

  dynamic "virtual_hub" {
    for_each = each.value.virtual_hub_id != null ? [1] : []
    content {
      virtual_hub_id  = each.value.virtual_hub_id
      public_ip_count = each.value.virtual_hub_public_ip_count
    }
  }

  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  for_each = var.firewall_rule_collection_groups

  name               = each.key
  firewall_policy_id = each.value.firewall_policy_id != null ? each.value.firewall_policy_id : azurerm_firewall_policy.this[each.value.firewall_policy_key].id
  priority           = each.value.priority

  dynamic "application_rule_collection" {
    for_each = each.value.application_rule_collections
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name                  = rule.value.name
          description           = rule.value.description
          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
          destination_fqdns     = rule.value.destination_fqdns
          destination_fqdn_tags = rule.value.destination_fqdn_tags
          destination_urls      = rule.value.destination_urls
          terminate_tls         = rule.value.terminate_tls
          web_categories        = rule.value.web_categories

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = each.value.network_rule_collections
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          description           = rule.value.description
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
          destination_addresses = rule.value.destination_addresses
          destination_ip_groups = rule.value.destination_ip_groups
          destination_fqdns     = rule.value.destination_fqdns
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }

  dynamic "nat_rule_collection" {
    for_each = each.value.nat_rule_collections
    content {
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority
      action   = nat_rule_collection.value.action

      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.value.name
          description         = rule.value.description
          protocols           = rule.value.protocols
          source_addresses    = rule.value.source_addresses
          source_ip_groups    = rule.value.source_ip_groups
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_fqdn     = rule.value.translated_fqdn
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}

resource "azurerm_public_ip" "vpn_gateway" {
  for_each = var.vpn_gateways

  name                = "${each.key}-pip"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zones
  tags                = var.tags
}

resource "azurerm_public_ip" "vpn_gateway_secondary" {
  for_each = { for k, v in var.vpn_gateways : k => v if v.active_active }

  name                = "${each.key}-pip-2"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zones
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  for_each = var.vpn_gateways

  name                             = each.key
  location                         = each.value.location
  resource_group_name              = each.value.resource_group_name
  type                             = "Vpn"
  vpn_type                         = each.value.vpn_type
  active_active                    = each.value.active_active
  enable_bgp                       = each.value.enable_bgp
  sku                              = each.value.sku
  generation                       = each.value.generation
  private_ip_address_enabled       = each.value.private_ip_address_enabled
  default_local_network_gateway_id = each.value.default_local_network_gateway_id

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[each.key].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = each.value.subnet_id
  }

  dynamic "ip_configuration" {
    for_each = each.value.active_active ? [1] : []
    content {
      name                          = "vnetGatewayConfig2"
      public_ip_address_id          = azurerm_public_ip.vpn_gateway_secondary[each.key].id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = each.value.subnet_id
    }
  }

  dynamic "bgp_settings" {
    for_each = each.value.bgp_settings != null ? [each.value.bgp_settings] : []
    content {
      asn         = bgp_settings.value.asn
      peer_weight = bgp_settings.value.peer_weight

      dynamic "peering_addresses" {
        for_each = bgp_settings.value.peering_addresses != null ? bgp_settings.value.peering_addresses : []
        content {
          ip_configuration_name = peering_addresses.value.ip_configuration_name
          apipa_addresses       = peering_addresses.value.apipa_addresses
        }
      }
    }
  }

  dynamic "vpn_client_configuration" {
    for_each = each.value.vpn_client_configuration != null ? [each.value.vpn_client_configuration] : []
    content {
      address_space         = vpn_client_configuration.value.address_space
      vpn_client_protocols  = vpn_client_configuration.value.vpn_client_protocols
      vpn_auth_types        = vpn_client_configuration.value.vpn_auth_types
      aad_tenant            = vpn_client_configuration.value.aad_tenant
      aad_audience          = vpn_client_configuration.value.aad_audience
      aad_issuer            = vpn_client_configuration.value.aad_issuer
      radius_server_address = vpn_client_configuration.value.radius_server_address
      radius_server_secret  = vpn_client_configuration.value.radius_server_secret

      dynamic "root_certificate" {
        for_each = vpn_client_configuration.value.root_certificates != null ? vpn_client_configuration.value.root_certificates : []
        content {
          name             = root_certificate.value.name
          public_cert_data = root_certificate.value.public_cert_data
        }
      }

      dynamic "revoked_certificate" {
        for_each = vpn_client_configuration.value.revoked_certificates != null ? vpn_client_configuration.value.revoked_certificates : []
        content {
          name       = revoked_certificate.value.name
          thumbprint = revoked_certificate.value.thumbprint
        }
      }
    }
  }

  tags = var.tags
}

resource "azurerm_public_ip" "expressroute" {
  for_each = var.expressroute_gateways

  name                = "${each.key}-pip"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zones
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "expressroute" {
  for_each = var.expressroute_gateways

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  type                = "ExpressRoute"
  sku                 = each.value.sku

  ip_configuration {
    name                          = "expressRouteGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.expressroute[each.key].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = each.value.subnet_id
  }

  tags = var.tags
}

resource "azurerm_local_network_gateway" "this" {
  for_each = var.local_network_gateways

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  gateway_address     = each.value.gateway_address
  gateway_fqdn        = each.value.gateway_fqdn
  address_space       = each.value.address_space

  dynamic "bgp_settings" {
    for_each = each.value.bgp_settings != null ? [each.value.bgp_settings] : []
    content {
      asn                 = bgp_settings.value.asn
      bgp_peering_address = bgp_settings.value.bgp_peering_address
      peer_weight         = bgp_settings.value.peer_weight
    }
  }

  tags = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each = var.gateway_connections

  name                               = each.key
  location                           = each.value.location
  resource_group_name                = each.value.resource_group_name
  type                               = each.value.type
  virtual_network_gateway_id         = each.value.virtual_network_gateway_id != null ? each.value.virtual_network_gateway_id : azurerm_virtual_network_gateway.vpn[each.value.vpn_gateway_key].id
  local_network_gateway_id           = each.value.local_network_gateway_id != null ? each.value.local_network_gateway_id : (each.value.local_network_gateway_key != null ? azurerm_local_network_gateway.this[each.value.local_network_gateway_key].id : null)
  express_route_circuit_id           = each.value.express_route_circuit_id
  peer_virtual_network_gateway_id    = each.value.peer_virtual_network_gateway_id
  shared_key                         = each.value.shared_key
  connection_protocol                = each.value.connection_protocol
  enable_bgp                         = each.value.enable_bgp
  dpd_timeout_seconds                = each.value.dpd_timeout_seconds
  connection_mode                    = each.value.connection_mode
  routing_weight                     = each.value.routing_weight
  express_route_gateway_bypass       = each.value.express_route_gateway_bypass
  private_link_fast_path_enabled     = each.value.private_link_fast_path_enabled
  local_azure_ip_address_enabled     = each.value.local_azure_ip_address_enabled
  use_policy_based_traffic_selectors = each.value.use_policy_based_traffic_selectors
  egress_nat_rule_ids                = each.value.egress_nat_rule_ids
  ingress_nat_rule_ids               = each.value.ingress_nat_rule_ids

  dynamic "ipsec_policy" {
    for_each = each.value.ipsec_policy != null ? [each.value.ipsec_policy] : []
    content {
      dh_group         = ipsec_policy.value.dh_group
      ike_encryption   = ipsec_policy.value.ike_encryption
      ike_integrity    = ipsec_policy.value.ike_integrity
      ipsec_encryption = ipsec_policy.value.ipsec_encryption
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity
      pfs_group        = ipsec_policy.value.pfs_group
      sa_datasize      = ipsec_policy.value.sa_datasize
      sa_lifetime      = ipsec_policy.value.sa_lifetime
    }
  }

  dynamic "traffic_selector_policy" {
    for_each = each.value.traffic_selector_policies != null ? each.value.traffic_selector_policies : []
    content {
      local_address_cidrs  = traffic_selector_policy.value.local_address_cidrs
      remote_address_cidrs = traffic_selector_policy.value.remote_address_cidrs
    }
  }

  tags = var.tags
}

resource "azurerm_public_ip" "bastion" {
  for_each = var.bastions

  name                = "${each.key}-pip"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zones
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  for_each = var.bastions

  name                   = each.key
  location               = each.value.location
  resource_group_name    = each.value.resource_group_name
  sku                    = each.value.sku
  scale_units            = each.value.scale_units
  copy_paste_enabled     = each.value.copy_paste_enabled
  file_copy_enabled      = each.value.file_copy_enabled
  shareable_link_enabled = each.value.shareable_link_enabled
  tunneling_enabled      = each.value.tunneling_enabled
  ip_connect_enabled     = each.value.ip_connect_enabled
  kerberos_enabled       = each.value.kerberos_enabled

  ip_configuration {
    name                 = "configuration"
    subnet_id            = each.value.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion[each.key].id
  }

  tags = var.tags
}

resource "azurerm_express_route_circuit" "this" {
  for_each = var.expressroute_circuits

  name                  = each.key
  location              = each.value.location
  resource_group_name   = each.value.resource_group_name
  service_provider_name = each.value.service_provider_name
  peering_location      = each.value.peering_location
  bandwidth_in_mbps     = each.value.bandwidth_in_mbps
  express_route_port_id = each.value.express_route_port_id
  bandwidth_in_gbps     = each.value.bandwidth_in_gbps

  sku {
    tier   = each.value.sku_tier
    family = each.value.sku_family
  }

  allow_classic_operations = each.value.allow_classic_operations

  tags = var.tags
}

resource "azurerm_express_route_circuit_peering" "this" {
  for_each = var.expressroute_peerings

  peering_type                  = each.value.peering_type
  express_route_circuit_name    = each.value.express_route_circuit_name != null ? each.value.express_route_circuit_name : azurerm_express_route_circuit.this[each.value.circuit_key].name
  resource_group_name           = each.value.resource_group_name
  peer_asn                      = each.value.peer_asn
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix
  vlan_id                       = each.value.vlan_id
  shared_key                    = each.value.shared_key
  route_filter_id               = each.value.route_filter_id
  ipv4_enabled                  = each.value.ipv4_enabled

  dynamic "microsoft_peering_config" {
    for_each = each.value.microsoft_peering_config != null ? [each.value.microsoft_peering_config] : []
    content {
      advertised_public_prefixes = microsoft_peering_config.value.advertised_public_prefixes
      customer_asn               = microsoft_peering_config.value.customer_asn
      routing_registry_name      = microsoft_peering_config.value.routing_registry_name
      advertised_communities     = microsoft_peering_config.value.advertised_communities
    }
  }
}

resource "azurerm_route_filter" "this" {
  for_each = var.route_filters

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = var.tags
}

resource "azurerm_route_filter_rule" "this" {
  for_each = var.route_filter_rules

  name            = each.key
  route_filter_id = each.value.route_filter_id != null ? each.value.route_filter_id : azurerm_route_filter.this[each.value.route_filter_key].id
  access          = each.value.access
  rule_type       = each.value.rule_type
  communities     = each.value.communities
}
