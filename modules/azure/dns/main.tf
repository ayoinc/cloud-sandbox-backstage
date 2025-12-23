terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

resource "azurerm_dns_zone" "this" {
  for_each = var.public_dns_zones

  name                = each.key
  resource_group_name = each.value.resource_group_name

  dynamic "soa_record" {
    for_each = each.value.soa_record != null ? [each.value.soa_record] : []
    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
      host_name    = soa_record.value.host_name
    }
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "this" {
  for_each = var.private_dns_zones

  name                = each.key
  resource_group_name = each.value.resource_group_name

  dynamic "soa_record" {
    for_each = each.value.soa_record != null ? [each.value.soa_record] : []
    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
    }
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.private_dns_zone_vnet_links

  name                  = each.key
  resource_group_name   = each.value.resource_group_name
  private_dns_zone_name = each.value.private_dns_zone_name != null ? each.value.private_dns_zone_name : azurerm_private_dns_zone.this[each.value.private_dns_zone_key].name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled
  tags                  = var.tags
}

resource "azurerm_dns_a_record" "this" {
  for_each = var.dns_a_records

  name                = each.key
  zone_name           = each.value.zone_name != null ? each.value.zone_name : azurerm_dns_zone.this[each.value.zone_key].name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  target_resource_id  = each.value.target_resource_id
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "this" {
  for_each = var.private_dns_a_records

  name                = each.key
  zone_name           = each.value.zone_name != null ? each.value.zone_name : azurerm_private_dns_zone.this[each.value.zone_key].name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = var.tags
}

resource "azurerm_dns_cname_record" "this" {
  for_each = var.dns_cname_records

  name                = each.key
  zone_name           = each.value.zone_name != null ? each.value.zone_name : azurerm_dns_zone.this[each.value.zone_key].name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
  target_resource_id  = each.value.target_resource_id
  tags                = var.tags
}

resource "azurerm_private_dns_cname_record" "this" {
  for_each = var.private_dns_cname_records

  name                = each.key
  zone_name           = each.value.zone_name != null ? each.value.zone_name : azurerm_private_dns_zone.this[each.value.zone_key].name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
  tags                = var.tags
}

resource "azurerm_dns_txt_record" "this" {
  for_each = var.dns_txt_records

  name                = each.key
  zone_name           = each.value.zone_name != null ? each.value.zone_name : azurerm_dns_zone.this[each.value.zone_key].name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }

  tags = var.tags
}

resource "azurerm_dns_mx_record" "this" {
  for_each = var.dns_mx_records

  name                = each.key
  zone_name           = each.value.zone_name != null ? each.value.zone_name : azurerm_dns_zone.this[each.value.zone_key].name
  resource_group_name = each.value.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }

  tags = var.tags
}

resource "azurerm_traffic_manager_profile" "this" {
  for_each = var.traffic_manager_profiles

  name                   = each.key
  resource_group_name    = each.value.resource_group_name
  traffic_routing_method = each.value.traffic_routing_method
  profile_status         = each.value.profile_status
  traffic_view_enabled   = each.value.traffic_view_enabled
  max_return             = each.value.max_return

  dns_config {
    relative_name = each.value.dns_config.relative_name
    ttl           = each.value.dns_config.ttl
  }

  monitor_config {
    protocol                     = each.value.monitor_config.protocol
    port                         = each.value.monitor_config.port
    path                         = each.value.monitor_config.path
    interval_in_seconds          = each.value.monitor_config.interval_in_seconds
    timeout_in_seconds           = each.value.monitor_config.timeout_in_seconds
    tolerated_number_of_failures = each.value.monitor_config.tolerated_number_of_failures
    expected_status_code_ranges  = each.value.monitor_config.expected_status_code_ranges

    dynamic "custom_header" {
      for_each = each.value.monitor_config.custom_headers != null ? each.value.monitor_config.custom_headers : []
      content {
        name  = custom_header.value.name
        value = custom_header.value.value
      }
    }
  }

  tags = var.tags
}

resource "azurerm_traffic_manager_azure_endpoint" "this" {
  for_each = var.traffic_manager_azure_endpoints

  name                 = each.key
  profile_id           = each.value.profile_id != null ? each.value.profile_id : azurerm_traffic_manager_profile.this[each.value.profile_key].id
  target_resource_id   = each.value.target_resource_id
  weight               = each.value.weight
  priority             = each.value.priority
  enabled              = each.value.enabled
  geo_mappings         = each.value.geo_mappings
  always_serve_enabled = each.value.always_serve_enabled

  dynamic "custom_header" {
    for_each = each.value.custom_headers != null ? each.value.custom_headers : []
    content {
      name  = custom_header.value.name
      value = custom_header.value.value
    }
  }

  dynamic "subnet" {
    for_each = each.value.subnets != null ? each.value.subnets : []
    content {
      first = subnet.value.first
      last  = subnet.value.last
      scope = subnet.value.scope
    }
  }
}

resource "azurerm_traffic_manager_external_endpoint" "this" {
  for_each = var.traffic_manager_external_endpoints

  name                 = each.key
  profile_id           = each.value.profile_id != null ? each.value.profile_id : azurerm_traffic_manager_profile.this[each.value.profile_key].id
  target               = each.value.target
  weight               = each.value.weight
  priority             = each.value.priority
  enabled              = each.value.enabled
  geo_mappings         = each.value.geo_mappings
  always_serve_enabled = each.value.always_serve_enabled
  endpoint_location    = each.value.endpoint_location

  dynamic "custom_header" {
    for_each = each.value.custom_headers != null ? each.value.custom_headers : []
    content {
      name  = custom_header.value.name
      value = custom_header.value.value
    }
  }

  dynamic "subnet" {
    for_each = each.value.subnets != null ? each.value.subnets : []
    content {
      first = subnet.value.first
      last  = subnet.value.last
      scope = subnet.value.scope
    }
  }
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  for_each = var.frontdoor_profiles

  name                     = each.key
  resource_group_name      = each.value.resource_group_name
  sku_name                 = each.value.sku_name
  response_timeout_seconds = each.value.response_timeout_seconds
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  for_each = var.frontdoor_endpoints

  name                     = each.key
  cdn_frontdoor_profile_id = each.value.profile_id != null ? each.value.profile_id : azurerm_cdn_frontdoor_profile.this[each.value.profile_key].id
  enabled                  = each.value.enabled
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each = var.frontdoor_origin_groups

  name                                                      = each.key
  cdn_frontdoor_profile_id                                  = each.value.profile_id != null ? each.value.profile_id : azurerm_cdn_frontdoor_profile.this[each.value.profile_key].id
  session_affinity_enabled                                  = each.value.session_affinity_enabled
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  load_balancing {
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
  }

  dynamic "health_probe" {
    for_each = each.value.health_probe != null ? [each.value.health_probe] : []
    content {
      protocol            = health_probe.value.protocol
      interval_in_seconds = health_probe.value.interval_in_seconds
      request_type        = health_probe.value.request_type
      path                = health_probe.value.path
    }
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = var.frontdoor_origins

  name                           = each.key
  cdn_frontdoor_origin_group_id  = each.value.origin_group_id != null ? each.value.origin_group_id : azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_key].id
  enabled                        = each.value.enabled
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.origin_host_header
  priority                       = each.value.priority
  weight                         = each.value.weight

  dynamic "private_link" {
    for_each = each.value.private_link != null ? [each.value.private_link] : []
    content {
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = var.frontdoor_routes

  name                            = each.key
  cdn_frontdoor_endpoint_id       = each.value.endpoint_id != null ? each.value.endpoint_id : azurerm_cdn_frontdoor_endpoint.this[each.value.endpoint_key].id
  cdn_frontdoor_origin_group_id   = each.value.origin_group_id != null ? each.value.origin_group_id : azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_key].id
  cdn_frontdoor_origin_ids        = each.value.origin_ids != null ? each.value.origin_ids : [for k in each.value.origin_keys : azurerm_cdn_frontdoor_origin.this[k].id]
  enabled                         = each.value.enabled
  forwarding_protocol             = each.value.forwarding_protocol
  https_redirect_enabled          = each.value.https_redirect_enabled
  patterns_to_match               = each.value.patterns_to_match
  supported_protocols             = each.value.supported_protocols
  cdn_frontdoor_custom_domain_ids = each.value.custom_domain_ids
  cdn_frontdoor_rule_set_ids      = each.value.rule_set_ids
  link_to_default_domain          = each.value.link_to_default_domain

  dynamic "cache" {
    for_each = each.value.cache != null ? [each.value.cache] : []
    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each = var.frontdoor_custom_domains

  name                     = each.key
  cdn_frontdoor_profile_id = each.value.profile_id != null ? each.value.profile_id : azurerm_cdn_frontdoor_profile.this[each.value.profile_key].id
  dns_zone_id              = each.value.dns_zone_id
  host_name                = each.value.host_name

  tls {
    certificate_type        = each.value.tls.certificate_type
    minimum_tls_version     = each.value.tls.minimum_tls_version
    cdn_frontdoor_secret_id = each.value.tls.cdn_frontdoor_secret_id
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  for_each = var.frontdoor_waf_policies

  name                              = each.key
  resource_group_name               = each.value.resource_group_name
  sku_name                          = each.value.sku_name
  enabled                           = each.value.enabled
  mode                              = each.value.mode
  redirect_url                      = each.value.redirect_url
  custom_block_response_status_code = each.value.custom_block_response_status_code
  custom_block_response_body        = each.value.custom_block_response_body

  dynamic "custom_rule" {
    for_each = each.value.custom_rules != null ? each.value.custom_rules : []
    content {
      name                           = custom_rule.value.name
      enabled                        = custom_rule.value.enabled
      priority                       = custom_rule.value.priority
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold
      type                           = custom_rule.value.type
      action                         = custom_rule.value.action

      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions
        content {
          match_variable     = match_condition.value.match_variable
          operator           = match_condition.value.operator
          negation_condition = match_condition.value.negation_condition
          match_values       = match_condition.value.match_values
          selector           = match_condition.value.selector
          transforms         = match_condition.value.transforms
        }
      }
    }
  }

  dynamic "managed_rule" {
    for_each = each.value.managed_rules != null ? each.value.managed_rules : []
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action

      dynamic "override" {
        for_each = managed_rule.value.overrides != null ? managed_rule.value.overrides : []
        content {
          rule_group_name = override.value.rule_group_name

          dynamic "rule" {
            for_each = override.value.rules != null ? override.value.rules : []
            content {
              rule_id = rule.value.rule_id
              enabled = rule.value.enabled
              action  = rule.value.action
            }
          }
        }
      }
    }
  }

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  for_each = var.frontdoor_security_policies

  name                     = each.key
  cdn_frontdoor_profile_id = each.value.profile_id != null ? each.value.profile_id : azurerm_cdn_frontdoor_profile.this[each.value.profile_key].id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = each.value.waf_policy_id != null ? each.value.waf_policy_id : azurerm_cdn_frontdoor_firewall_policy.this[each.value.waf_policy_key].id

      association {
        patterns_to_match = each.value.patterns_to_match

        dynamic "domain" {
          for_each = each.value.domain_ids != null ? each.value.domain_ids : [for k in each.value.endpoint_keys : azurerm_cdn_frontdoor_endpoint.this[k].id]
          content {
            cdn_frontdoor_domain_id = domain.value
          }
        }
      }
    }
  }
}
