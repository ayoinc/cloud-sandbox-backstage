variable "project_name" {
  description = "The name of the project for labeling purposes"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "notification_channels" {
  description = "List of notification channels for alerting (supports email, slack, pagerduty, sms)"
  type = list(object({
    display_name = string
    type         = string
    labels       = map(string)
    enabled      = optional(bool, true)
  }))
  default = []

  validation {
    condition = alltrue([
      for channel in var.notification_channels :
      contains(["email", "slack", "pagerduty", "sms", "webhook_tokenauth", "pubsub"], channel.type)
    ])
    error_message = "Notification channel type must be one of: email, slack, pagerduty, sms, webhook_tokenauth, pubsub."
  }
}

variable "alert_policies" {
  description = "List of alert policies to create"
  type = list(object({
    display_name = string
    combiner     = string
    conditions = list(object({
      display_name = string
      condition_threshold = optional(object({
        filter          = string
        duration        = string
        comparison      = string
        threshold_value = optional(number)
        aggregations = optional(list(object({
          alignment_period     = optional(string)
          per_series_aligner   = optional(string)
          cross_series_reducer = optional(string)
          group_by_fields      = optional(list(string))
        })))
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
      }))
      condition_absent = optional(object({
        filter   = string
        duration = string
        aggregations = optional(list(object({
          alignment_period     = optional(string)
          per_series_aligner   = optional(string)
          cross_series_reducer = optional(string)
          group_by_fields      = optional(list(string))
        })))
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
      }))
      condition_monitoring_query_language = optional(object({
        query    = string
        duration = string
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
      }))
      condition_matched_log = optional(object({
        filter           = string
        label_extractors = optional(map(string))
      }))
    }))
    notification_channels = list(string)
    documentation = optional(object({
      content   = string
      mime_type = optional(string, "text/markdown")
    }))
    enabled = optional(bool, true)
    alert_strategy = optional(object({
      auto_close = optional(string)
      notification_rate_limit = optional(object({
        period = string
      }))
      notification_channel_strategy = optional(list(object({
        notification_channel_names = optional(list(string))
        renotify_interval          = optional(string)
      })))
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for policy in var.alert_policies :
      contains(["OR", "AND", "AND_WITH_MATCHING_RESOURCE"], policy.combiner)
    ])
    error_message = "Alert policy combiner must be one of: OR, AND, AND_WITH_MATCHING_RESOURCE."
  }
}

variable "uptime_checks" {
  description = "List of uptime check configurations"
  type = list(object({
    display_name = string
    timeout      = string
    period       = string
    http_check = optional(object({
      path           = optional(string, "/")
      port           = optional(number, 443)
      use_ssl        = optional(bool, true)
      validate_ssl   = optional(bool, true)
      request_method = optional(string, "GET")
      body           = optional(string)
      content_type   = optional(string)
      headers        = optional(map(string))
      mask_headers   = optional(bool, false)
      auth_info = optional(object({
        username = string
        password = string
      }))
      accepted_response_status_codes = optional(list(object({
        status_class = optional(string)
        status_value = optional(number)
      })))
    }))
    tcp_check = optional(object({
      port = number
    }))
    monitored_resource = optional(object({
      type   = string
      labels = map(string)
    }))
    selected_regions = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for check in var.uptime_checks :
      contains(["10s", "60s", "300s", "600s", "900s"], check.period)
    ])
    error_message = "Uptime check period must be one of: 10s, 60s, 300s, 600s, 900s."
  }
}

variable "dashboards" {
  description = "List of custom dashboards to create"
  type = list(object({
    display_name   = string
    dashboard_json = string
  }))
  default = []
}

variable "resource_groups" {
  description = "List of resource groups for organizing monitored resources"
  type = list(object({
    display_name = string
    filter       = string
    parent_name  = optional(string)
  }))
  default = []
}

variable "custom_services" {
  description = "List of custom services for SLO definitions"
  type = list(object({
    service_id   = string
    display_name = string
    telemetry = optional(object({
      resource_name = string
    }))
  }))
  default = []
}

variable "slos" {
  description = "List of SLO configurations for custom services"
  type = list(object({
    display_name = string
    service_name = string
    slo_id       = string
    goal         = number
    basic_sli = optional(object({
      latency = optional(object({
        threshold = string
      }))
      availability = optional(object({
        enabled = optional(bool, true)
      }))
      method   = optional(list(string))
      location = optional(list(string))
      version  = optional(list(string))
    }))
    request_based_sli = optional(object({
      good_total_ratio = optional(object({
        good_service_filter  = optional(string)
        bad_service_filter   = optional(string)
        total_service_filter = optional(string)
      }))
      distribution_cut = optional(object({
        distribution_filter = string
        range = optional(object({
          min = optional(number)
          max = optional(number)
        }))
      }))
    }))
    windows_based_sli = optional(object({
      window_period          = optional(string)
      good_bad_metric_filter = optional(string)
      threshold              = optional(number)
      performance = optional(object({
        good_total_ratio = optional(object({
          good_service_filter  = optional(string)
          bad_service_filter   = optional(string)
          total_service_filter = optional(string)
        }))
        distribution_cut = optional(object({
          distribution_filter = string
          range = optional(object({
            min = optional(number)
            max = optional(number)
          }))
        }))
      }))
      basic_sli_performance = optional(object({
        latency = optional(object({
          threshold = string
        }))
        availability = optional(object({
          enabled = optional(bool, true)
        }))
        method   = optional(list(string))
        location = optional(list(string))
        version  = optional(list(string))
      }))
    }))
    rolling_period_days = optional(number)
    calendar_period     = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for slo in var.slos :
      slo.goal > 0 && slo.goal <= 1
    ])
    error_message = "SLO goal must be between 0 and 1 (exclusive of 0, inclusive of 1)."
  }
}
