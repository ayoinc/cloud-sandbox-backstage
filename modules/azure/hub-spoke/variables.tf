variable "tags" {
  type    = map(string)
  default = {}
}

variable "firewall_policies" {
  type = map(object({
    resource_group_name               = string
    location                          = string
    sku                               = optional(string, "Standard")
    threat_intelligence_mode          = optional(string, "Alert")
    sql_redirect_allowed              = optional(bool)
    private_ip_ranges                 = optional(list(string))
    auto_learn_private_ranges_enabled = optional(bool)
    dns = optional(object({
      proxy_enabled = optional(bool, true)
      servers       = optional(list(string))
    }))
    intrusion_detection = optional(object({
      mode = optional(string, "Alert")
      signature_overrides = optional(list(object({
        id    = string
        state = string
      })))
      traffic_bypass = optional(list(object({
        name                  = string
        protocol              = string
        destination_addresses = optional(list(string))
        destination_ip_groups = optional(list(string))
        destination_ports     = optional(list(string))
        source_addresses      = optional(list(string))
        source_ip_groups      = optional(list(string))
      })))
    }))
    threat_intelligence_allowlist = optional(object({
      fqdns        = optional(list(string))
      ip_addresses = optional(list(string))
    }))
    tls_certificate = optional(object({
      key_vault_secret_id = string
      name                = string
    }))
    explicit_proxy = optional(object({
      enabled         = optional(bool, true)
      http_port       = optional(number)
      https_port      = optional(number)
      enable_pac_file = optional(bool)
      pac_file_port   = optional(number)
      pac_file        = optional(string)
    }))
  }))
  default = {}
}

variable "firewalls" {
  type = map(object({
    location                    = string
    resource_group_name         = string
    sku_name                    = optional(string, "AZFW_VNet")
    sku_tier                    = optional(string, "Standard")
    firewall_policy_id          = optional(string)
    firewall_policy_key         = optional(string)
    subnet_id                   = string
    management_subnet_id        = optional(string)
    zones                       = optional(list(string), ["1", "2", "3"])
    threat_intel_mode           = optional(string, "Alert")
    dns_proxy_enabled           = optional(bool)
    dns_servers                 = optional(list(string))
    virtual_hub_id              = optional(string)
    virtual_hub_public_ip_count = optional(number, 1)
  }))
  default = {}
}

variable "firewall_rule_collection_groups" {
  type = map(object({
    firewall_policy_id  = optional(string)
    firewall_policy_key = optional(string)
    priority            = number
    application_rule_collections = optional(list(object({
      name     = string
      priority = number
      action   = string
      rules = list(object({
        name                  = string
        description           = optional(string)
        source_addresses      = optional(list(string))
        source_ip_groups      = optional(list(string))
        destination_fqdns     = optional(list(string))
        destination_fqdn_tags = optional(list(string))
        destination_urls      = optional(list(string))
        terminate_tls         = optional(bool)
        web_categories        = optional(list(string))
        protocols = list(object({
          type = string
          port = number
        }))
      }))
    })), [])
    network_rule_collections = optional(list(object({
      name     = string
      priority = number
      action   = string
      rules = list(object({
        name                  = string
        description           = optional(string)
        protocols             = list(string)
        source_addresses      = optional(list(string))
        source_ip_groups      = optional(list(string))
        destination_addresses = optional(list(string))
        destination_ip_groups = optional(list(string))
        destination_fqdns     = optional(list(string))
        destination_ports     = list(string)
      }))
    })), [])
    nat_rule_collections = optional(list(object({
      name     = string
      priority = number
      action   = optional(string, "Dnat")
      rules = list(object({
        name                = string
        description         = optional(string)
        protocols           = list(string)
        source_addresses    = optional(list(string))
        source_ip_groups    = optional(list(string))
        destination_address = string
        destination_ports   = list(string)
        translated_address  = optional(string)
        translated_fqdn     = optional(string)
        translated_port     = string
      }))
    })), [])
  }))
  default = {}
}

variable "vpn_gateways" {
  type = map(object({
    location                         = string
    resource_group_name              = string
    subnet_id                        = string
    sku                              = optional(string, "VpnGw2AZ")
    generation                       = optional(string, "Generation2")
    vpn_type                         = optional(string, "RouteBased")
    active_active                    = optional(bool, false)
    enable_bgp                       = optional(bool, false)
    zones                            = optional(list(string), ["1", "2", "3"])
    private_ip_address_enabled       = optional(bool, false)
    default_local_network_gateway_id = optional(string)
    bgp_settings = optional(object({
      asn         = number
      peer_weight = optional(number)
      peering_addresses = optional(list(object({
        ip_configuration_name = string
        apipa_addresses       = optional(list(string))
      })))
    }))
    vpn_client_configuration = optional(object({
      address_space         = list(string)
      vpn_client_protocols  = optional(list(string))
      vpn_auth_types        = optional(list(string))
      aad_tenant            = optional(string)
      aad_audience          = optional(string)
      aad_issuer            = optional(string)
      radius_server_address = optional(string)
      radius_server_secret  = optional(string)
      root_certificates = optional(list(object({
        name             = string
        public_cert_data = string
      })))
      revoked_certificates = optional(list(object({
        name       = string
        thumbprint = string
      })))
    }))
  }))
  default = {}
}

variable "expressroute_gateways" {
  type = map(object({
    location            = string
    resource_group_name = string
    subnet_id           = string
    sku                 = optional(string, "ErGw1AZ")
    zones               = optional(list(string), ["1", "2", "3"])
  }))
  default = {}
}

variable "local_network_gateways" {
  type = map(object({
    location            = string
    resource_group_name = string
    gateway_address     = optional(string)
    gateway_fqdn        = optional(string)
    address_space       = optional(list(string))
    bgp_settings = optional(object({
      asn                 = number
      bgp_peering_address = string
      peer_weight         = optional(number)
    }))
  }))
  default = {}
}

variable "gateway_connections" {
  type = map(object({
    location                           = string
    resource_group_name                = string
    type                               = string
    virtual_network_gateway_id         = optional(string)
    vpn_gateway_key                    = optional(string)
    local_network_gateway_id           = optional(string)
    local_network_gateway_key          = optional(string)
    express_route_circuit_id           = optional(string)
    peer_virtual_network_gateway_id    = optional(string)
    shared_key                         = optional(string)
    connection_protocol                = optional(string, "IKEv2")
    enable_bgp                         = optional(bool, false)
    dpd_timeout_seconds                = optional(number, 45)
    connection_mode                    = optional(string, "Default")
    routing_weight                     = optional(number)
    express_route_gateway_bypass       = optional(bool, false)
    private_link_fast_path_enabled     = optional(bool, false)
    local_azure_ip_address_enabled     = optional(bool, false)
    use_policy_based_traffic_selectors = optional(bool, false)
    egress_nat_rule_ids                = optional(list(string))
    ingress_nat_rule_ids               = optional(list(string))
    ipsec_policy = optional(object({
      dh_group         = string
      ike_encryption   = string
      ike_integrity    = string
      ipsec_encryption = string
      ipsec_integrity  = string
      pfs_group        = string
      sa_datasize      = optional(number)
      sa_lifetime      = optional(number)
    }))
    traffic_selector_policies = optional(list(object({
      local_address_cidrs  = list(string)
      remote_address_cidrs = list(string)
    })))
  }))
  default   = {}
  sensitive = true
}

variable "bastions" {
  type = map(object({
    location               = string
    resource_group_name    = string
    subnet_id              = string
    sku                    = optional(string, "Standard")
    scale_units            = optional(number, 2)
    copy_paste_enabled     = optional(bool, true)
    file_copy_enabled      = optional(bool, true)
    shareable_link_enabled = optional(bool, false)
    tunneling_enabled      = optional(bool, true)
    ip_connect_enabled     = optional(bool, true)
    kerberos_enabled       = optional(bool, false)
    zones                  = optional(list(string))
  }))
  default = {}
}

variable "expressroute_circuits" {
  type = map(object({
    location                 = string
    resource_group_name      = string
    service_provider_name    = optional(string)
    peering_location         = optional(string)
    bandwidth_in_mbps        = optional(number)
    express_route_port_id    = optional(string)
    bandwidth_in_gbps        = optional(number)
    sku_tier                 = optional(string, "Standard")
    sku_family               = optional(string, "MeteredData")
    allow_classic_operations = optional(bool, false)
  }))
  default = {}
}

variable "expressroute_peerings" {
  type = map(object({
    peering_type                  = string
    express_route_circuit_name    = optional(string)
    circuit_key                   = optional(string)
    resource_group_name           = string
    peer_asn                      = optional(number)
    primary_peer_address_prefix   = optional(string)
    secondary_peer_address_prefix = optional(string)
    vlan_id                       = number
    shared_key                    = optional(string)
    route_filter_id               = optional(string)
    ipv4_enabled                  = optional(bool, true)
    microsoft_peering_config = optional(object({
      advertised_public_prefixes = list(string)
      customer_asn               = optional(number)
      routing_registry_name      = optional(string)
      advertised_communities     = optional(list(string))
    }))
  }))
  default   = {}
  sensitive = true
}

variable "route_filters" {
  type = map(object({
    location            = string
    resource_group_name = string
  }))
  default = {}
}

variable "route_filter_rules" {
  type = map(object({
    route_filter_id  = optional(string)
    route_filter_key = optional(string)
    access           = optional(string, "Allow")
    rule_type        = optional(string, "Community")
    communities      = list(string)
  }))
  default = {}
}
