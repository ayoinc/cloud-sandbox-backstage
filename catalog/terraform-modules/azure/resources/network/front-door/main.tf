terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

locals {
  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  tags = merge(local.default_tags, var.tags)

  origin_group_map = { for og in var.origin_groups : og.name => og }
  endpoint_map     = { for ep in var.endpoints : ep.name => ep }
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = var.profile_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  for_each = { for ep in var.endpoints : ep.name => ep }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  enabled                  = each.value.enabled

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each = { for og in var.origin_groups : og.name => og }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = each.value.session_affinity_enabled

  health_probe {
    interval_in_seconds = each.value.health_probe.interval_in_seconds
    path                = each.value.health_probe.path
    protocol            = each.value.health_probe.protocol
    request_type        = each.value.health_probe.request_type
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = { for origin in var.origins : origin.name => origin }

  name                           = each.value.name
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_name].id
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  enabled                        = each.value.enabled
  priority                       = each.value.priority
  weight                         = each.value.weight
}

resource "azurerm_cdn_frontdoor_rule_set" "this" {
  name                     = "${replace(var.profile_name, "-", "")}ruleset"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_rule" "security_headers" {
  name                      = "SecurityHeaders"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this.id
  order                     = 1
  behavior_on_match         = "Continue"

  actions {
    response_header_action {
      header_action = "Overwrite"
      header_name   = "X-Content-Type-Options"
      value         = "nosniff"
    }

    response_header_action {
      header_action = "Overwrite"
      header_name   = "X-Frame-Options"
      value         = "SAMEORIGIN"
    }

    response_header_action {
      header_action = "Overwrite"
      header_name   = "X-XSS-Protection"
      value         = "1; mode=block"
    }

    response_header_action {
      header_action = "Overwrite"
      header_name   = "Strict-Transport-Security"
      value         = "max-age=31536000; includeSubDomains"
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = { for route in var.routes : route.name => route }

  name                          = each.value.name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this[each.value.endpoint_name].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids      = [for origin_name in each.value.origin_names : azurerm_cdn_frontdoor_origin.this[origin_name].id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.this.id]

  enabled                = true
  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = each.value.supported_protocols
  forwarding_protocol    = each.value.forwarding_protocol
  https_redirect_enabled = each.value.https_redirect_enabled
  link_to_default_domain = true

  dynamic "cache" {
    for_each = each.value.cache_enabled ? [1] : []
    content {
      query_string_caching_behavior = "UseQueryString"
      compression_enabled           = true
      content_types_to_compress     = ["text/html", "text/css", "application/javascript", "application/json", "text/xml", "application/xml", "image/svg+xml"]
    }
  }

  cdn_frontdoor_custom_domain_ids = length(var.custom_domains) > 0 ? [for cd in azurerm_cdn_frontdoor_custom_domain.this : cd.id] : null

  depends_on = [
    azurerm_cdn_frontdoor_origin.this,
    azurerm_cdn_frontdoor_origin_group.this
  ]
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each = { for cd in var.custom_domains : cd.name => cd }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  host_name                = each.value.host_name
  dns_zone_id              = each.value.dns_zone_id

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count = var.waf_policy_id != null ? 1 : 0

  name                     = "${replace(var.profile_name, "-", "")}secpolicy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = var.waf_policy_id

      association {
        patterns_to_match = ["/*"]

        dynamic "domain" {
          for_each = azurerm_cdn_frontdoor_endpoint.this
          content {
            cdn_frontdoor_domain_id = domain.value.id
          }
        }

        dynamic "domain" {
          for_each = azurerm_cdn_frontdoor_custom_domain.this
          content {
            cdn_frontdoor_domain_id = domain.value.id
          }
        }
      }
    }
  }
}
