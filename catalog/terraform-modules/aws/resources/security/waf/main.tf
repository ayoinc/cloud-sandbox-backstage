terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.name}"

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_wafv2_web_acl" "this" {
  name        = local.name_prefix
  description = "WAF Web ACL for ${local.name_prefix}"
  scope       = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  # AWS Managed Rule Groups
  dynamic "rule" {
    for_each = var.managed_rule_groups
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name

          dynamic "rule_action_override" {
            for_each = rule.value.excluded_rules
            content {
              name = rule_action_override.value
              action_to_use {
                count {}
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name_prefix}-${rule.value.name}"
        sampled_requests_enabled   = true
      }
    }
  }

  # Rate-based Rules for DDoS Protection
  dynamic "rule" {
    for_each = var.rate_limit_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        rate_based_statement {
          limit              = rule.value.limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name_prefix}-${rule.value.name}"
        sampled_requests_enabled   = true
      }
    }
  }

  # IP Set Rules (Allow/Block Lists)
  dynamic "rule" {
    for_each = var.ip_set_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }

        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        ip_set_reference_statement {
          arn = rule.value.ip_set_arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name_prefix}-${rule.value.name}"
        sampled_requests_enabled   = true
      }
    }
  }

  # Custom Rules with Regex Patterns
  dynamic "rule" {
    for_each = var.custom_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }

        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        dynamic "byte_match_statement" {
          for_each = rule.value.statement_type == "byte_match" ? [rule.value.statement] : []
          content {
            search_string         = byte_match_statement.value.search_string
            positional_constraint = byte_match_statement.value.positional_constraint

            field_to_match {
              dynamic "uri_path" {
                for_each = byte_match_statement.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }

              dynamic "query_string" {
                for_each = byte_match_statement.value.field_to_match == "query_string" ? [1] : []
                content {}
              }

              dynamic "body" {
                for_each = byte_match_statement.value.field_to_match == "body" ? [1] : []
                content {}
              }

              dynamic "single_header" {
                for_each = byte_match_statement.value.field_to_match == "single_header" ? [1] : []
                content {
                  name = byte_match_statement.value.header_name
                }
              }
            }

            text_transformation {
              priority = 0
              type     = lookup(byte_match_statement.value, "text_transformation", "NONE")
            }
          }
        }

        dynamic "regex_pattern_set_reference_statement" {
          for_each = rule.value.statement_type == "regex_pattern_set" ? [rule.value.statement] : []
          content {
            arn = regex_pattern_set_reference_statement.value.arn

            field_to_match {
              dynamic "uri_path" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }

              dynamic "query_string" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match == "query_string" ? [1] : []
                content {}
              }

              dynamic "body" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match == "body" ? [1] : []
                content {}
              }

              dynamic "single_header" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match == "single_header" ? [1] : []
                content {
                  name = regex_pattern_set_reference_statement.value.header_name
                }
              }
            }

            text_transformation {
              priority = 0
              type     = lookup(regex_pattern_set_reference_statement.value, "text_transformation", "NONE")
            }
          }
        }

        dynamic "regex_match_statement" {
          for_each = rule.value.statement_type == "regex_match" ? [rule.value.statement] : []
          content {
            regex_string = regex_match_statement.value.regex_string

            field_to_match {
              dynamic "uri_path" {
                for_each = regex_match_statement.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }

              dynamic "query_string" {
                for_each = regex_match_statement.value.field_to_match == "query_string" ? [1] : []
                content {}
              }

              dynamic "body" {
                for_each = regex_match_statement.value.field_to_match == "body" ? [1] : []
                content {}
              }

              dynamic "single_header" {
                for_each = regex_match_statement.value.field_to_match == "single_header" ? [1] : []
                content {
                  name = regex_match_statement.value.header_name
                }
              }
            }

            text_transformation {
              priority = 0
              type     = lookup(regex_match_statement.value, "text_transformation", "NONE")
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name_prefix}-${rule.value.name}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.name_prefix
    sampled_requests_enabled   = true
  }

  tags = merge(local.default_tags, var.tags)
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_logging && length(var.log_destination_arns) > 0 ? 1 : 0

  log_destination_configs = var.log_destination_arns
  resource_arn            = aws_wafv2_web_acl.this.arn

  dynamic "logging_filter" {
    for_each = var.logging_filter != null ? [var.logging_filter] : []
    content {
      default_behavior = logging_filter.value.default_behavior

      dynamic "filter" {
        for_each = logging_filter.value.filters
        content {
          behavior    = filter.value.behavior
          requirement = filter.value.requirement

          dynamic "condition" {
            for_each = filter.value.conditions
            content {
              dynamic "action_condition" {
                for_each = condition.value.type == "action" ? [condition.value] : []
                content {
                  action = action_condition.value.action
                }
              }

              dynamic "label_name_condition" {
                for_each = condition.value.type == "label" ? [condition.value] : []
                content {
                  label_name = label_name_condition.value.label_name
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "redacted_fields" {
    for_each = var.redacted_fields
    content {
      dynamic "single_header" {
        for_each = redacted_fields.value.type == "single_header" ? [redacted_fields.value] : []
        content {
          name = single_header.value.name
        }
      }

      dynamic "uri_path" {
        for_each = redacted_fields.value.type == "uri_path" ? [1] : []
        content {}
      }

      dynamic "query_string" {
        for_each = redacted_fields.value.type == "query_string" ? [1] : []
        content {}
      }
    }
  }
}
