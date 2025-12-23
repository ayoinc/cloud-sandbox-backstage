variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "log_analytics_workspaces" {
  type = map(object({
    sku                        = optional(string, "PerGB2018")
    retention_in_days          = optional(number, 30)
    daily_quota_gb             = optional(number, -1)
    internet_ingestion_enabled = optional(bool, true)
    internet_query_enabled     = optional(bool, true)
  }))
  default = {}
}

variable "log_analytics_solutions" {
  type = map(object({
    workspace_key = string
    solution_name = string
    publisher     = optional(string, "Microsoft")
    product       = string
  }))
  default = {}
}

variable "application_insights" {
  type = map(object({
    workspace_key              = optional(string)
    workspace_id               = optional(string)
    application_type           = optional(string, "web")
    retention_in_days          = optional(number, 90)
    daily_data_cap_in_gb       = optional(number)
    sampling_percentage        = optional(number, 100)
    disable_ip_masking         = optional(bool, false)
    internet_ingestion_enabled = optional(bool, true)
    internet_query_enabled     = optional(bool, true)
  }))
  default = {}
}

variable "action_groups" {
  type = map(object({
    short_name = string
    enabled    = optional(bool, true)
    email_receivers = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool, true)
    })), [])
    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    webhook_receivers = optional(list(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool, true)
    })), [])
    azure_app_push_receivers = optional(list(object({
      name          = string
      email_address = string
    })), [])
  }))
  default = {}
}

variable "diagnostic_settings" {
  type = map(object({
    target_resource_id             = string
    workspace_key                  = optional(string)
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    log_categories                 = optional(list(string), [])
    metric_categories              = optional(list(string), [])
  }))
  default = {}
}

variable "metric_alerts" {
  type = map(object({
    scopes            = list(string)
    description       = optional(string, "")
    severity          = optional(number, 3)
    enabled           = optional(bool, true)
    frequency         = optional(string, "PT5M")
    window_size       = optional(string, "PT15M")
    auto_mitigate     = optional(bool, true)
    action_group_keys = optional(list(string), [])
    criteria = list(object({
      metric_namespace = string
      metric_name      = string
      aggregation      = string
      operator         = string
      threshold        = number
    }))
  }))
  default = {}
}

variable "activity_log_alerts" {
  type = map(object({
    scopes            = list(string)
    description       = optional(string, "")
    enabled           = optional(bool, true)
    action_group_keys = optional(list(string), [])
    criteria = object({
      category       = string
      operation_name = optional(string)
      level          = optional(string)
      status         = optional(string)
    })
  }))
  default = {}
}

variable "data_collection_rules" {
  type = map(object({
    kind = optional(string, "Linux")
    log_analytics_destinations = list(object({
      workspace_key = string
      name          = string
    }))
    data_flows = list(object({
      streams      = list(string)
      destinations = list(string)
    }))
    data_sources = optional(object({
      syslog = optional(list(object({
        facility_names = list(string)
        log_levels     = list(string)
        name           = string
        streams        = list(string)
      })))
      performance_counters = optional(list(object({
        counter_specifiers            = list(string)
        name                          = string
        sampling_frequency_in_seconds = number
        streams                       = list(string)
      })))
    }))
  }))
  default = {}
}

variable "private_link_scopes" {
  type    = map(object({}))
  default = {}
}

variable "private_link_scope_services" {
  type = map(object({
    scope_key          = string
    workspace_key      = optional(string)
    linked_resource_id = optional(string)
  }))
  default = {}
}
