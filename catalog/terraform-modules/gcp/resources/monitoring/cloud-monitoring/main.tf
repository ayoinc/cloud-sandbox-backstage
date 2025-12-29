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
  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Notification Channels (Email, Slack, PagerDuty, SMS)
resource "google_monitoring_notification_channel" "channels" {
  for_each = { for idx, channel in var.notification_channels : channel.display_name => channel }

  project      = var.project_id
  display_name = each.value.display_name
  type         = each.value.type
  labels       = each.value.labels
  enabled      = each.value.enabled

  user_labels = local.common_labels
}

# Alert Policies
resource "google_monitoring_alert_policy" "policies" {
  for_each = { for idx, policy in var.alert_policies : policy.display_name => policy }

  project      = var.project_id
  display_name = each.value.display_name
  combiner     = each.value.combiner
  enabled      = each.value.enabled

  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name

      dynamic "condition_threshold" {
        for_each = lookup(conditions.value, "condition_threshold", null) != null ? [conditions.value.condition_threshold] : []
        content {
          filter          = condition_threshold.value.filter
          duration        = condition_threshold.value.duration
          comparison      = condition_threshold.value.comparison
          threshold_value = lookup(condition_threshold.value, "threshold_value", null)

          dynamic "aggregations" {
            for_each = lookup(condition_threshold.value, "aggregations", [])
            content {
              alignment_period     = lookup(aggregations.value, "alignment_period", null)
              per_series_aligner   = lookup(aggregations.value, "per_series_aligner", null)
              cross_series_reducer = lookup(aggregations.value, "cross_series_reducer", null)
              group_by_fields      = lookup(aggregations.value, "group_by_fields", [])
            }
          }

          dynamic "trigger" {
            for_each = lookup(condition_threshold.value, "trigger", null) != null ? [condition_threshold.value.trigger] : []
            content {
              count   = lookup(trigger.value, "count", null)
              percent = lookup(trigger.value, "percent", null)
            }
          }
        }
      }

      dynamic "condition_absent" {
        for_each = lookup(conditions.value, "condition_absent", null) != null ? [conditions.value.condition_absent] : []
        content {
          filter   = condition_absent.value.filter
          duration = condition_absent.value.duration

          dynamic "aggregations" {
            for_each = lookup(condition_absent.value, "aggregations", [])
            content {
              alignment_period     = lookup(aggregations.value, "alignment_period", null)
              per_series_aligner   = lookup(aggregations.value, "per_series_aligner", null)
              cross_series_reducer = lookup(aggregations.value, "cross_series_reducer", null)
              group_by_fields      = lookup(aggregations.value, "group_by_fields", [])
            }
          }

          dynamic "trigger" {
            for_each = lookup(condition_absent.value, "trigger", null) != null ? [condition_absent.value.trigger] : []
            content {
              count   = lookup(trigger.value, "count", null)
              percent = lookup(trigger.value, "percent", null)
            }
          }
        }
      }

      dynamic "condition_monitoring_query_language" {
        for_each = lookup(conditions.value, "condition_monitoring_query_language", null) != null ? [conditions.value.condition_monitoring_query_language] : []
        content {
          query    = condition_monitoring_query_language.value.query
          duration = condition_monitoring_query_language.value.duration

          dynamic "trigger" {
            for_each = lookup(condition_monitoring_query_language.value, "trigger", null) != null ? [condition_monitoring_query_language.value.trigger] : []
            content {
              count   = lookup(trigger.value, "count", null)
              percent = lookup(trigger.value, "percent", null)
            }
          }
        }
      }

      dynamic "condition_matched_log" {
        for_each = lookup(conditions.value, "condition_matched_log", null) != null ? [conditions.value.condition_matched_log] : []
        content {
          filter           = condition_matched_log.value.filter
          label_extractors = lookup(condition_matched_log.value, "label_extractors", null)
        }
      }
    }
  }

  notification_channels = [
    for channel_name in each.value.notification_channels :
    google_monitoring_notification_channel.channels[channel_name].id
  ]

  dynamic "documentation" {
    for_each = each.value.documentation != null ? [each.value.documentation] : []
    content {
      content   = lookup(documentation.value, "content", null)
      mime_type = lookup(documentation.value, "mime_type", "text/markdown")
    }
  }

  dynamic "alert_strategy" {
    for_each = each.value.alert_strategy != null ? [each.value.alert_strategy] : []
    content {
      auto_close = lookup(alert_strategy.value, "auto_close", null)

      dynamic "notification_rate_limit" {
        for_each = lookup(alert_strategy.value, "notification_rate_limit", null) != null ? [alert_strategy.value.notification_rate_limit] : []
        content {
          period = notification_rate_limit.value.period
        }
      }

      dynamic "notification_channel_strategy" {
        for_each = lookup(alert_strategy.value, "notification_channel_strategy", [])
        content {
          notification_channel_names = lookup(notification_channel_strategy.value, "notification_channel_names", [])
          renotify_interval          = lookup(notification_channel_strategy.value, "renotify_interval", null)
        }
      }
    }
  }

  user_labels = local.common_labels
}

# Uptime Checks
resource "google_monitoring_uptime_check_config" "checks" {
  for_each = { for idx, check in var.uptime_checks : check.display_name => check }

  project      = var.project_id
  display_name = each.value.display_name
  timeout      = each.value.timeout
  period       = each.value.period

  dynamic "http_check" {
    for_each = each.value.http_check != null ? [each.value.http_check] : []
    content {
      path           = lookup(http_check.value, "path", "/")
      port           = lookup(http_check.value, "port", 443)
      use_ssl        = lookup(http_check.value, "use_ssl", true)
      validate_ssl   = lookup(http_check.value, "validate_ssl", true)
      request_method = lookup(http_check.value, "request_method", "GET")
      body           = lookup(http_check.value, "body", null)
      content_type   = lookup(http_check.value, "content_type", null)
      headers        = lookup(http_check.value, "headers", {})
      mask_headers   = lookup(http_check.value, "mask_headers", false)

      dynamic "auth_info" {
        for_each = lookup(http_check.value, "auth_info", null) != null ? [http_check.value.auth_info] : []
        content {
          username = auth_info.value.username
          password = auth_info.value.password
        }
      }

      dynamic "accepted_response_status_codes" {
        for_each = lookup(http_check.value, "accepted_response_status_codes", [])
        content {
          status_class = lookup(accepted_response_status_codes.value, "status_class", null)
          status_value = lookup(accepted_response_status_codes.value, "status_value", null)
        }
      }
    }
  }

  dynamic "tcp_check" {
    for_each = each.value.tcp_check != null ? [each.value.tcp_check] : []
    content {
      port = tcp_check.value.port
    }
  }

  dynamic "monitored_resource" {
    for_each = each.value.monitored_resource != null ? [each.value.monitored_resource] : []
    content {
      type   = monitored_resource.value.type
      labels = monitored_resource.value.labels
    }
  }

  selected_regions = each.value.selected_regions

  user_labels = local.common_labels
}

# Custom Dashboards
resource "google_monitoring_dashboard" "dashboards" {
  for_each = { for idx, dashboard in var.dashboards : dashboard.display_name => dashboard }

  project        = var.project_id
  dashboard_json = each.value.dashboard_json
}

# Resource Groups
resource "google_monitoring_group" "groups" {
  for_each = { for idx, group in var.resource_groups : group.display_name => group }

  project      = var.project_id
  display_name = each.value.display_name
  filter       = each.value.filter
  parent_name  = each.value.parent_name
}

# Custom Services for SLOs
resource "google_monitoring_custom_service" "services" {
  for_each = { for idx, service in var.custom_services : service.display_name => service }

  project      = var.project_id
  service_id   = each.value.service_id
  display_name = each.value.display_name

  dynamic "telemetry" {
    for_each = lookup(each.value, "telemetry", null) != null ? [each.value.telemetry] : []
    content {
      resource_name = telemetry.value.resource_name
    }
  }

  user_labels = local.common_labels
}

# SLOs for Custom Services
resource "google_monitoring_slo" "slos" {
  for_each = { for idx, slo in var.slos : slo.display_name => slo }

  project      = var.project_id
  service      = google_monitoring_custom_service.services[each.value.service_name].service_id
  slo_id       = each.value.slo_id
  display_name = each.value.display_name
  goal         = each.value.goal

  dynamic "basic_sli" {
    for_each = lookup(each.value, "basic_sli", null) != null ? [each.value.basic_sli] : []
    content {
      dynamic "latency" {
        for_each = lookup(basic_sli.value, "latency", null) != null ? [basic_sli.value.latency] : []
        content {
          threshold = latency.value.threshold
        }
      }

      dynamic "availability" {
        for_each = lookup(basic_sli.value, "availability", null) != null ? [basic_sli.value.availability] : []
        content {
          enabled = lookup(availability.value, "enabled", true)
        }
      }

      method   = lookup(basic_sli.value, "method", null)
      location = lookup(basic_sli.value, "location", null)
      version  = lookup(basic_sli.value, "version", null)
    }
  }

  dynamic "request_based_sli" {
    for_each = lookup(each.value, "request_based_sli", null) != null ? [each.value.request_based_sli] : []
    content {
      dynamic "good_total_ratio" {
        for_each = lookup(request_based_sli.value, "good_total_ratio", null) != null ? [request_based_sli.value.good_total_ratio] : []
        content {
          good_service_filter  = lookup(good_total_ratio.value, "good_service_filter", null)
          bad_service_filter   = lookup(good_total_ratio.value, "bad_service_filter", null)
          total_service_filter = lookup(good_total_ratio.value, "total_service_filter", null)
        }
      }

      dynamic "distribution_cut" {
        for_each = lookup(request_based_sli.value, "distribution_cut", null) != null ? [request_based_sli.value.distribution_cut] : []
        content {
          distribution_filter = distribution_cut.value.distribution_filter

          dynamic "range" {
            for_each = lookup(distribution_cut.value, "range", null) != null ? [distribution_cut.value.range] : []
            content {
              min = lookup(range.value, "min", null)
              max = lookup(range.value, "max", null)
            }
          }
        }
      }
    }
  }

  dynamic "windows_based_sli" {
    for_each = lookup(each.value, "windows_based_sli", null) != null ? [each.value.windows_based_sli] : []
    content {
      window_period          = lookup(windows_based_sli.value, "window_period", null)
      good_bad_metric_filter = lookup(windows_based_sli.value, "good_bad_metric_filter", null)
      good_total_ratio_threshold {
        threshold = lookup(windows_based_sli.value, "threshold", null)

        dynamic "performance" {
          for_each = lookup(windows_based_sli.value, "performance", null) != null ? [windows_based_sli.value.performance] : []
          content {
            dynamic "good_total_ratio" {
              for_each = lookup(performance.value, "good_total_ratio", null) != null ? [performance.value.good_total_ratio] : []
              content {
                good_service_filter  = lookup(good_total_ratio.value, "good_service_filter", null)
                bad_service_filter   = lookup(good_total_ratio.value, "bad_service_filter", null)
                total_service_filter = lookup(good_total_ratio.value, "total_service_filter", null)
              }
            }

            dynamic "distribution_cut" {
              for_each = lookup(performance.value, "distribution_cut", null) != null ? [performance.value.distribution_cut] : []
              content {
                distribution_filter = distribution_cut.value.distribution_filter

                dynamic "range" {
                  for_each = lookup(distribution_cut.value, "range", null) != null ? [distribution_cut.value.range] : []
                  content {
                    min = lookup(range.value, "min", null)
                    max = lookup(range.value, "max", null)
                  }
                }
              }
            }
          }
        }

        dynamic "basic_sli_performance" {
          for_each = lookup(windows_based_sli.value, "basic_sli_performance", null) != null ? [windows_based_sli.value.basic_sli_performance] : []
          content {
            dynamic "latency" {
              for_each = lookup(basic_sli_performance.value, "latency", null) != null ? [basic_sli_performance.value.latency] : []
              content {
                threshold = latency.value.threshold
              }
            }

            dynamic "availability" {
              for_each = lookup(basic_sli_performance.value, "availability", null) != null ? [basic_sli_performance.value.availability] : []
              content {
                enabled = lookup(availability.value, "enabled", true)
              }
            }

            method   = lookup(basic_sli_performance.value, "method", null)
            location = lookup(basic_sli_performance.value, "location", null)
            version  = lookup(basic_sli_performance.value, "version", null)
          }
        }
      }
    }
  }

  rolling_period_days = lookup(each.value, "rolling_period_days", null)
  calendar_period     = lookup(each.value, "calendar_period", null)

  user_labels = local.common_labels
}
