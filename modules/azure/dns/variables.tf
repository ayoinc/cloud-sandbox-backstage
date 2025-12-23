variable "tags" {
  type    = map(string)
  default = {}
}

variable "public_dns_zones" {
  type = map(object({
    resource_group_name = string
    soa_record = optional(object({
      email        = string
      expire_time  = optional(number)
      minimum_ttl  = optional(number)
      refresh_time = optional(number)
      retry_time   = optional(number)
      ttl          = optional(number)
      host_name    = optional(string)
    }))
  }))
  default = {}
}

variable "private_dns_zones" {
  type = map(object({
    resource_group_name = string
    soa_record = optional(object({
      email        = optional(string)
      expire_time  = optional(number)
      minimum_ttl  = optional(number)
      refresh_time = optional(number)
      retry_time   = optional(number)
      ttl          = optional(number)
    }))
  }))
  default = {}
}

variable "private_dns_zone_vnet_links" {
  type = map(object({
    resource_group_name   = string
    private_dns_zone_name = optional(string)
    private_dns_zone_key  = optional(string)
    virtual_network_id    = string
    registration_enabled  = optional(bool, false)
  }))
  default = {}
}

variable "dns_a_records" {
  type = map(object({
    zone_name           = optional(string)
    zone_key            = optional(string)
    resource_group_name = string
    ttl                 = number
    records             = optional(list(string))
    target_resource_id  = optional(string)
  }))
  default = {}
}

variable "private_dns_a_records" {
  type = map(object({
    zone_name           = optional(string)
    zone_key            = optional(string)
    resource_group_name = string
    ttl                 = number
    records             = list(string)
  }))
  default = {}
}

variable "dns_cname_records" {
  type = map(object({
    zone_name           = optional(string)
    zone_key            = optional(string)
    resource_group_name = string
    ttl                 = number
    record              = optional(string)
    target_resource_id  = optional(string)
  }))
  default = {}
}

variable "private_dns_cname_records" {
  type = map(object({
    zone_name           = optional(string)
    zone_key            = optional(string)
    resource_group_name = string
    ttl                 = number
    record              = string
  }))
  default = {}
}

variable "dns_txt_records" {
  type = map(object({
    zone_name           = optional(string)
    zone_key            = optional(string)
    resource_group_name = string
    ttl                 = number
    records             = list(string)
  }))
  default = {}
}

variable "dns_mx_records" {
  type = map(object({
    zone_name           = optional(string)
    zone_key            = optional(string)
    resource_group_name = string
    ttl                 = number
    records = list(object({
      preference = number
      exchange   = string
    }))
  }))
  default = {}
}

variable "traffic_manager_profiles" {
  type = map(object({
    resource_group_name    = string
    traffic_routing_method = string
    profile_status         = optional(string, "Enabled")
    traffic_view_enabled   = optional(bool, false)
    max_return             = optional(number)
    dns_config = object({
      relative_name = string
      ttl           = number
    })
    monitor_config = object({
      protocol                     = string
      port                         = number
      path                         = optional(string)
      interval_in_seconds          = optional(number, 30)
      timeout_in_seconds           = optional(number, 10)
      tolerated_number_of_failures = optional(number, 3)
      expected_status_code_ranges  = optional(list(string))
      custom_headers = optional(list(object({
        name  = string
        value = string
      })))
    })
  }))
  default = {}
}

variable "traffic_manager_azure_endpoints" {
  type = map(object({
    profile_id           = optional(string)
    profile_key          = optional(string)
    target_resource_id   = string
    weight               = optional(number)
    priority             = optional(number)
    enabled              = optional(bool, true)
    geo_mappings         = optional(list(string))
    always_serve_enabled = optional(bool, false)
    custom_headers = optional(list(object({
      name  = string
      value = string
    })))
    subnets = optional(list(object({
      first = string
      last  = optional(string)
      scope = optional(number)
    })))
  }))
  default = {}
}

variable "traffic_manager_external_endpoints" {
  type = map(object({
    profile_id           = optional(string)
    profile_key          = optional(string)
    target               = string
    weight               = optional(number)
    priority             = optional(number)
    enabled              = optional(bool, true)
    geo_mappings         = optional(list(string))
    always_serve_enabled = optional(bool, false)
    endpoint_location    = optional(string)
    custom_headers = optional(list(object({
      name  = string
      value = string
    })))
    subnets = optional(list(object({
      first = string
      last  = optional(string)
      scope = optional(number)
    })))
  }))
  default = {}
}

variable "frontdoor_profiles" {
  type = map(object({
    resource_group_name      = string
    sku_name                 = string
    response_timeout_seconds = optional(number, 60)
  }))
  default = {}
}

variable "frontdoor_endpoints" {
  type = map(object({
    profile_id  = optional(string)
    profile_key = optional(string)
    enabled     = optional(bool, true)
  }))
  default = {}
}

variable "frontdoor_origin_groups" {
  type = map(object({
    profile_id                                                = optional(string)
    profile_key                                               = optional(string)
    session_affinity_enabled                                  = optional(bool, false)
    restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number, 10)
    load_balancing = object({
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 3)
      additional_latency_in_milliseconds = optional(number, 50)
    })
    health_probe = optional(object({
      protocol            = string
      interval_in_seconds = optional(number, 100)
      request_type        = optional(string, "HEAD")
      path                = optional(string, "/")
    }))
  }))
  default = {}
}

variable "frontdoor_origins" {
  type = map(object({
    origin_group_id                = optional(string)
    origin_group_key               = optional(string)
    enabled                        = optional(bool, true)
    certificate_name_check_enabled = optional(bool, true)
    host_name                      = string
    http_port                      = optional(number, 80)
    https_port                     = optional(number, 443)
    origin_host_header             = optional(string)
    priority                       = optional(number, 1)
    weight                         = optional(number, 1000)
    private_link = optional(object({
      location               = string
      private_link_target_id = string
      request_message        = optional(string)
      target_type            = optional(string)
    }))
  }))
  default = {}
}

variable "frontdoor_routes" {
  type = map(object({
    endpoint_id            = optional(string)
    endpoint_key           = optional(string)
    origin_group_id        = optional(string)
    origin_group_key       = optional(string)
    origin_ids             = optional(list(string))
    origin_keys            = optional(list(string))
    enabled                = optional(bool, true)
    forwarding_protocol    = optional(string, "HttpsOnly")
    https_redirect_enabled = optional(bool, true)
    patterns_to_match      = list(string)
    supported_protocols    = optional(list(string), ["Http", "Https"])
    custom_domain_ids      = optional(list(string))
    rule_set_ids           = optional(list(string))
    link_to_default_domain = optional(bool, true)
    cache = optional(object({
      query_string_caching_behavior = optional(string, "IgnoreQueryString")
      query_strings                 = optional(list(string))
      compression_enabled           = optional(bool, false)
      content_types_to_compress     = optional(list(string))
    }))
  }))
  default = {}
}

variable "frontdoor_custom_domains" {
  type = map(object({
    profile_id  = optional(string)
    profile_key = optional(string)
    dns_zone_id = optional(string)
    host_name   = string
    tls = object({
      certificate_type        = optional(string, "ManagedCertificate")
      minimum_tls_version     = optional(string, "TLS12")
      cdn_frontdoor_secret_id = optional(string)
    })
  }))
  default = {}
}

variable "frontdoor_waf_policies" {
  type = map(object({
    resource_group_name               = string
    sku_name                          = string
    enabled                           = optional(bool, true)
    mode                              = optional(string, "Prevention")
    redirect_url                      = optional(string)
    custom_block_response_status_code = optional(number)
    custom_block_response_body        = optional(string)
    custom_rules = optional(list(object({
      name                           = string
      enabled                        = optional(bool, true)
      priority                       = number
      rate_limit_duration_in_minutes = optional(number)
      rate_limit_threshold           = optional(number)
      type                           = string
      action                         = string
      match_conditions = list(object({
        match_variable     = string
        operator           = string
        negation_condition = optional(bool, false)
        match_values       = list(string)
        selector           = optional(string)
        transforms         = optional(list(string))
      }))
    })))
    managed_rules = optional(list(object({
      type    = string
      version = string
      action  = optional(string, "Block")
      overrides = optional(list(object({
        rule_group_name = string
        rules = optional(list(object({
          rule_id = string
          enabled = optional(bool, true)
          action  = optional(string)
        })))
      })))
    })))
  }))
  default = {}
}

variable "frontdoor_security_policies" {
  type = map(object({
    profile_id        = optional(string)
    profile_key       = optional(string)
    waf_policy_id     = optional(string)
    waf_policy_key    = optional(string)
    patterns_to_match = list(string)
    domain_ids        = optional(list(string))
    endpoint_keys     = optional(list(string))
  }))
  default = {}
}
