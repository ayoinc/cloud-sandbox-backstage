terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  policy_name = "${var.project_name}-${var.environment}-${var.name}"
}

resource "google_compute_security_policy" "policy" {
  project     = var.project_id
  name        = local.policy_name
  description = var.description
  type        = var.type

  dynamic "adaptive_protection_config" {
    for_each = var.adaptive_protection_config != null ? [var.adaptive_protection_config] : []
    content {
      dynamic "layer_7_ddos_defense_config" {
        for_each = adaptive_protection_config.value.layer_7_ddos_defense_config != null ? [adaptive_protection_config.value.layer_7_ddos_defense_config] : []
        content {
          enable          = layer_7_ddos_defense_config.value.enable
          rule_visibility = layer_7_ddos_defense_config.value.rule_visibility
        }
      }
    }
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      preview     = rule.value.preview

      match {
        versioned_expr = rule.value.match_versioned_expr

        dynamic "config" {
          for_each = rule.value.match_config != null ? [rule.value.match_config] : []
          content {
            src_ip_ranges = config.value.src_ip_ranges
          }
        }

        dynamic "expr" {
          for_each = rule.value.match_expr != null ? [rule.value.match_expr] : []
          content {
            expression = expr.value.expression
          }
        }
      }

      dynamic "rate_limit_options" {
        for_each = rule.value.rate_limit_options != null ? [rule.value.rate_limit_options] : []
        content {
          conform_action = rate_limit_options.value.conform_action
          exceed_action  = rate_limit_options.value.exceed_action

          dynamic "enforce_on_key_configs" {
            for_each = rate_limit_options.value.enforce_on_key_configs != null ? rate_limit_options.value.enforce_on_key_configs : []
            content {
              enforce_on_key_type = enforce_on_key_configs.value.enforce_on_key_type
              enforce_on_key_name = enforce_on_key_configs.value.enforce_on_key_name
            }
          }

          dynamic "rate_limit_threshold" {
            for_each = rate_limit_options.value.rate_limit_threshold != null ? [rate_limit_options.value.rate_limit_threshold] : []
            content {
              count        = rate_limit_threshold.value.count
              interval_sec = rate_limit_threshold.value.interval_sec
            }
          }

          dynamic "ban_threshold" {
            for_each = rate_limit_options.value.ban_threshold != null ? [rate_limit_options.value.ban_threshold] : []
            content {
              count        = ban_threshold.value.count
              interval_sec = ban_threshold.value.interval_sec
            }
          }

          ban_duration_sec = rate_limit_options.value.ban_duration_sec
        }
      }

      dynamic "preconfigured_waf_config" {
        for_each = rule.value.preconfigured_waf_config != null ? [rule.value.preconfigured_waf_config] : []
        content {
          dynamic "exclusion" {
            for_each = preconfigured_waf_config.value.exclusions != null ? preconfigured_waf_config.value.exclusions : []
            content {
              target_rule_set = exclusion.value.target_rule_set
              target_rule_ids = exclusion.value.target_rule_ids

              dynamic "request_header" {
                for_each = exclusion.value.request_headers != null ? exclusion.value.request_headers : []
                content {
                  operator = request_header.value.operator
                  value    = request_header.value.value
                }
              }

              dynamic "request_cookie" {
                for_each = exclusion.value.request_cookies != null ? exclusion.value.request_cookies : []
                content {
                  operator = request_cookie.value.operator
                  value    = request_cookie.value.value
                }
              }

              dynamic "request_uri" {
                for_each = exclusion.value.request_uris != null ? exclusion.value.request_uris : []
                content {
                  operator = request_uri.value.operator
                  value    = request_uri.value.value
                }
              }

              dynamic "request_query_param" {
                for_each = exclusion.value.request_query_params != null ? exclusion.value.request_query_params : []
                content {
                  operator = request_query_param.value.operator
                  value    = request_query_param.value.value
                }
              }
            }
          }
        }
      }
    }
  }

  # Default rule - required for security policies
  rule {
    action      = var.default_rule_action
    priority    = 2147483647
    description = "Default rule"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
