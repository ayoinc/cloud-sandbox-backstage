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
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  topic_name  = var.topic_name != null ? var.topic_name : "${var.project_name}-${var.environment}-topic"
  domain_name = var.domain_name != null ? var.domain_name : "${var.project_name}-${var.environment}-domain"
}

# Custom Event Grid Topic
resource "azurerm_eventgrid_topic" "this" {
  count = var.create_custom_topic ? 1 : 0

  name                = local.topic_name
  location            = var.location
  resource_group_name = var.resource_group_name
  input_schema        = var.input_schema

  tags = local.common_tags
}

# System Topic for Azure Service Events
resource "azurerm_eventgrid_system_topic" "this" {
  count = var.create_system_topic ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-system-topic"
  location               = var.location
  resource_group_name    = var.resource_group_name
  source_arm_resource_id = var.system_topic_source_arm_resource_id
  topic_type             = var.system_topic_type

  tags = local.common_tags
}

# Event Grid Domain for Multi-tenant Scenarios
resource "azurerm_eventgrid_domain" "this" {
  count = var.create_domain ? 1 : 0

  name                = local.domain_name
  location            = var.location
  resource_group_name = var.resource_group_name
  input_schema        = var.input_schema

  tags = local.common_tags
}

# Event Subscriptions for Custom Topic
resource "azurerm_eventgrid_event_subscription" "custom_topic" {
  for_each = var.create_custom_topic ? { for sub in var.subscriptions : sub.name => sub } : {}

  name  = each.value.name
  scope = azurerm_eventgrid_topic.this[0].id

  included_event_types = each.value.included_event_types

  # Subject Filter
  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
      case_sensitive      = subject_filter.value.case_sensitive
    }
  }

  # Advanced Filters
  dynamic "advanced_filter" {
    for_each = each.value.advanced_filters != null ? each.value.advanced_filters : []
    content {
      dynamic "string_in" {
        for_each = advanced_filter.value.type == "string_in" ? [advanced_filter.value] : []
        content {
          key    = string_in.value.key
          values = string_in.value.values
        }
      }

      dynamic "string_not_in" {
        for_each = advanced_filter.value.type == "string_not_in" ? [advanced_filter.value] : []
        content {
          key    = string_not_in.value.key
          values = string_not_in.value.values
        }
      }

      dynamic "string_begins_with" {
        for_each = advanced_filter.value.type == "string_begins_with" ? [advanced_filter.value] : []
        content {
          key    = string_begins_with.value.key
          values = string_begins_with.value.values
        }
      }

      dynamic "string_ends_with" {
        for_each = advanced_filter.value.type == "string_ends_with" ? [advanced_filter.value] : []
        content {
          key    = string_ends_with.value.key
          values = string_ends_with.value.values
        }
      }

      dynamic "string_contains" {
        for_each = advanced_filter.value.type == "string_contains" ? [advanced_filter.value] : []
        content {
          key    = string_contains.value.key
          values = string_contains.value.values
        }
      }

      dynamic "number_in" {
        for_each = advanced_filter.value.type == "number_in" ? [advanced_filter.value] : []
        content {
          key    = number_in.value.key
          values = number_in.value.values
        }
      }

      dynamic "number_not_in" {
        for_each = advanced_filter.value.type == "number_not_in" ? [advanced_filter.value] : []
        content {
          key    = number_not_in.value.key
          values = number_not_in.value.values
        }
      }

      dynamic "number_less_than" {
        for_each = advanced_filter.value.type == "number_less_than" ? [advanced_filter.value] : []
        content {
          key   = number_less_than.value.key
          value = number_less_than.value.value
        }
      }

      dynamic "number_greater_than" {
        for_each = advanced_filter.value.type == "number_greater_than" ? [advanced_filter.value] : []
        content {
          key   = number_greater_than.value.key
          value = number_greater_than.value.value
        }
      }

      dynamic "number_less_than_or_equals" {
        for_each = advanced_filter.value.type == "number_less_than_or_equals" ? [advanced_filter.value] : []
        content {
          key   = number_less_than_or_equals.value.key
          value = number_less_than_or_equals.value.value
        }
      }

      dynamic "number_greater_than_or_equals" {
        for_each = advanced_filter.value.type == "number_greater_than_or_equals" ? [advanced_filter.value] : []
        content {
          key   = number_greater_than_or_equals.value.key
          value = number_greater_than_or_equals.value.value
        }
      }

      dynamic "bool_equals" {
        for_each = advanced_filter.value.type == "bool_equals" ? [advanced_filter.value] : []
        content {
          key   = bool_equals.value.key
          value = bool_equals.value.value
        }
      }

      dynamic "is_null_or_undefined" {
        for_each = advanced_filter.value.type == "is_null_or_undefined" ? [advanced_filter.value] : []
        content {
          key = is_null_or_undefined.value.key
        }
      }

      dynamic "is_not_null" {
        for_each = advanced_filter.value.type == "is_not_null" ? [advanced_filter.value] : []
        content {
          key = is_not_null.value.key
        }
      }
    }
  }

  # Webhook Endpoint
  dynamic "webhook_endpoint" {
    for_each = each.value.endpoint_type == "webhook" ? [1] : []
    content {
      url                               = each.value.endpoint_url
      max_events_per_batch              = lookup(each.value, "max_events_per_batch", 1)
      preferred_batch_size_in_kilobytes = lookup(each.value, "preferred_batch_size_in_kilobytes", 64)
    }
  }

  # Storage Queue Endpoint
  dynamic "storage_queue_endpoint" {
    for_each = each.value.endpoint_type == "storage_queue" ? [1] : []
    content {
      storage_account_id                    = each.value.storage_account_id
      queue_name                            = each.value.queue_name
      queue_message_time_to_live_in_seconds = lookup(each.value, "queue_message_time_to_live_in_seconds", 604800)
    }
  }

  # Service Bus Queue Endpoint
  dynamic "service_bus_queue_endpoint_id" {
    for_each = each.value.endpoint_type == "service_bus_queue" ? [1] : []
    content {
      service_bus_queue_endpoint_id = each.value.service_bus_queue_id
    }
  }

  # Service Bus Topic Endpoint
  dynamic "service_bus_topic_endpoint_id" {
    for_each = each.value.endpoint_type == "service_bus_topic" ? [1] : []
    content {
      service_bus_topic_endpoint_id = each.value.service_bus_topic_id
    }
  }

  # Event Hub Endpoint
  dynamic "eventhub_endpoint_id" {
    for_each = each.value.endpoint_type == "eventhub" ? [1] : []
    content {
      eventhub_endpoint_id = each.value.eventhub_id
    }
  }

  # Azure Function Endpoint
  dynamic "azure_function_endpoint" {
    for_each = each.value.endpoint_type == "azure_function" ? [1] : []
    content {
      function_id                       = each.value.function_id
      max_events_per_batch              = lookup(each.value, "max_events_per_batch", 1)
      preferred_batch_size_in_kilobytes = lookup(each.value, "preferred_batch_size_in_kilobytes", 64)
    }
  }

  # Retry Policy
  retry_policy {
    max_delivery_attempts = lookup(each.value, "max_delivery_attempts", 30)
    event_time_to_live    = lookup(each.value, "event_time_to_live", 1440)
  }

  # Dead Letter Destination
  dynamic "storage_blob_dead_letter_destination" {
    for_each = lookup(each.value, "dead_letter_storage_account_id", null) != null ? [1] : []
    content {
      storage_account_id          = each.value.dead_letter_storage_account_id
      storage_blob_container_name = each.value.dead_letter_container_name
    }
  }

  labels = lookup(each.value, "labels", [])
}

# Event Subscriptions for System Topic
resource "azurerm_eventgrid_system_topic_event_subscription" "this" {
  for_each = var.create_system_topic ? { for sub in var.subscriptions : sub.name => sub } : {}

  name                = each.value.name
  system_topic        = azurerm_eventgrid_system_topic.this[0].name
  resource_group_name = var.resource_group_name

  included_event_types = each.value.included_event_types

  # Subject Filter
  dynamic "subject_filter" {
    for_each = each.value.subject_filter != null ? [each.value.subject_filter] : []
    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
      case_sensitive      = subject_filter.value.case_sensitive
    }
  }

  # Advanced Filters
  dynamic "advanced_filter" {
    for_each = each.value.advanced_filters != null ? each.value.advanced_filters : []
    content {
      dynamic "string_in" {
        for_each = advanced_filter.value.type == "string_in" ? [advanced_filter.value] : []
        content {
          key    = string_in.value.key
          values = string_in.value.values
        }
      }

      dynamic "string_not_in" {
        for_each = advanced_filter.value.type == "string_not_in" ? [advanced_filter.value] : []
        content {
          key    = string_not_in.value.key
          values = string_not_in.value.values
        }
      }

      dynamic "string_begins_with" {
        for_each = advanced_filter.value.type == "string_begins_with" ? [advanced_filter.value] : []
        content {
          key    = string_begins_with.value.key
          values = string_begins_with.value.values
        }
      }

      dynamic "string_ends_with" {
        for_each = advanced_filter.value.type == "string_ends_with" ? [advanced_filter.value] : []
        content {
          key    = string_ends_with.value.key
          values = string_ends_with.value.values
        }
      }

      dynamic "string_contains" {
        for_each = advanced_filter.value.type == "string_contains" ? [advanced_filter.value] : []
        content {
          key    = string_contains.value.key
          values = string_contains.value.values
        }
      }

      dynamic "number_in" {
        for_each = advanced_filter.value.type == "number_in" ? [advanced_filter.value] : []
        content {
          key    = number_in.value.key
          values = number_in.value.values
        }
      }

      dynamic "number_not_in" {
        for_each = advanced_filter.value.type == "number_not_in" ? [advanced_filter.value] : []
        content {
          key    = number_not_in.value.key
          values = number_not_in.value.values
        }
      }

      dynamic "number_less_than" {
        for_each = advanced_filter.value.type == "number_less_than" ? [advanced_filter.value] : []
        content {
          key   = number_less_than.value.key
          value = number_less_than.value.value
        }
      }

      dynamic "number_greater_than" {
        for_each = advanced_filter.value.type == "number_greater_than" ? [advanced_filter.value] : []
        content {
          key   = number_greater_than.value.key
          value = number_greater_than.value.value
        }
      }

      dynamic "number_less_than_or_equals" {
        for_each = advanced_filter.value.type == "number_less_than_or_equals" ? [advanced_filter.value] : []
        content {
          key   = number_less_than_or_equals.value.key
          value = number_less_than_or_equals.value.value
        }
      }

      dynamic "number_greater_than_or_equals" {
        for_each = advanced_filter.value.type == "number_greater_than_or_equals" ? [advanced_filter.value] : []
        content {
          key   = number_greater_than_or_equals.value.key
          value = number_greater_than_or_equals.value.value
        }
      }

      dynamic "bool_equals" {
        for_each = advanced_filter.value.type == "bool_equals" ? [advanced_filter.value] : []
        content {
          key   = bool_equals.value.key
          value = bool_equals.value.value
        }
      }

      dynamic "is_null_or_undefined" {
        for_each = advanced_filter.value.type == "is_null_or_undefined" ? [advanced_filter.value] : []
        content {
          key = is_null_or_undefined.value.key
        }
      }

      dynamic "is_not_null" {
        for_each = advanced_filter.value.type == "is_not_null" ? [advanced_filter.value] : []
        content {
          key = is_not_null.value.key
        }
      }
    }
  }

  # Webhook Endpoint
  dynamic "webhook_endpoint" {
    for_each = each.value.endpoint_type == "webhook" ? [1] : []
    content {
      url                               = each.value.endpoint_url
      max_events_per_batch              = lookup(each.value, "max_events_per_batch", 1)
      preferred_batch_size_in_kilobytes = lookup(each.value, "preferred_batch_size_in_kilobytes", 64)
    }
  }

  # Storage Queue Endpoint
  dynamic "storage_queue_endpoint" {
    for_each = each.value.endpoint_type == "storage_queue" ? [1] : []
    content {
      storage_account_id                    = each.value.storage_account_id
      queue_name                            = each.value.queue_name
      queue_message_time_to_live_in_seconds = lookup(each.value, "queue_message_time_to_live_in_seconds", 604800)
    }
  }

  # Service Bus Queue Endpoint
  service_bus_queue_endpoint_id = each.value.endpoint_type == "service_bus_queue" ? each.value.service_bus_queue_id : null

  # Service Bus Topic Endpoint
  service_bus_topic_endpoint_id = each.value.endpoint_type == "service_bus_topic" ? each.value.service_bus_topic_id : null

  # Event Hub Endpoint
  eventhub_endpoint_id = each.value.endpoint_type == "eventhub" ? each.value.eventhub_id : null

  # Azure Function Endpoint
  dynamic "azure_function_endpoint" {
    for_each = each.value.endpoint_type == "azure_function" ? [1] : []
    content {
      function_id                       = each.value.function_id
      max_events_per_batch              = lookup(each.value, "max_events_per_batch", 1)
      preferred_batch_size_in_kilobytes = lookup(each.value, "preferred_batch_size_in_kilobytes", 64)
    }
  }

  # Retry Policy
  retry_policy {
    max_delivery_attempts = lookup(each.value, "max_delivery_attempts", 30)
    event_time_to_live    = lookup(each.value, "event_time_to_live", 1440)
  }

  # Dead Letter Destination
  dynamic "storage_blob_dead_letter_destination" {
    for_each = lookup(each.value, "dead_letter_storage_account_id", null) != null ? [1] : []
    content {
      storage_account_id          = each.value.dead_letter_storage_account_id
      storage_blob_container_name = each.value.dead_letter_container_name
    }
  }

  labels = lookup(each.value, "labels", [])
}
