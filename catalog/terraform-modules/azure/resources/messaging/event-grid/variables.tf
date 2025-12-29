variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "topic_name" {
  description = "The name of the Event Grid topic. If not provided, a default name will be generated"
  type        = string
  default     = null
}

variable "create_custom_topic" {
  description = "Whether to create a custom Event Grid topic"
  type        = bool
  default     = true
}

variable "create_system_topic" {
  description = "Whether to create a system topic for Azure service events"
  type        = bool
  default     = false
}

variable "system_topic_source_arm_resource_id" {
  description = "The ARM resource ID of the source for the system topic (e.g., Storage Account, Resource Group)"
  type        = string
  default     = null
}

variable "system_topic_type" {
  description = "The type of system topic (e.g., Microsoft.Storage.StorageAccounts, Microsoft.Resources.ResourceGroups)"
  type        = string
  default     = null
}

variable "input_schema" {
  description = "The schema for input events (EventGridSchema, CloudEventSchemaV1_0, or CustomEventSchema)"
  type        = string
  default     = "EventGridSchema"

  validation {
    condition     = contains(["EventGridSchema", "CloudEventSchemaV1_0", "CustomEventSchema"], var.input_schema)
    error_message = "input_schema must be one of: EventGridSchema, CloudEventSchemaV1_0, CustomEventSchema"
  }
}

variable "subscriptions" {
  description = "List of event subscriptions to create"
  type = list(object({
    name                 = string
    endpoint_type        = string
    endpoint_url         = optional(string)
    included_event_types = optional(list(string))
    subject_filter = optional(object({
      subject_begins_with = optional(string)
      subject_ends_with   = optional(string)
      case_sensitive      = optional(bool, false)
    }))
    advanced_filters = optional(list(object({
      type   = string
      key    = string
      values = optional(list(any))
      value  = optional(any)
    })))
    # Webhook specific
    max_events_per_batch              = optional(number, 1)
    preferred_batch_size_in_kilobytes = optional(number, 64)
    # Storage Queue specific
    storage_account_id                    = optional(string)
    queue_name                            = optional(string)
    queue_message_time_to_live_in_seconds = optional(number, 604800)
    # Service Bus specific
    service_bus_queue_id = optional(string)
    service_bus_topic_id = optional(string)
    # Event Hub specific
    eventhub_id = optional(string)
    # Azure Function specific
    function_id = optional(string)
    # Retry policy
    max_delivery_attempts = optional(number, 30)
    event_time_to_live    = optional(number, 1440)
    # Dead letter
    dead_letter_storage_account_id = optional(string)
    dead_letter_container_name     = optional(string)
    # Labels
    labels = optional(list(string), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for sub in var.subscriptions : contains(
        ["webhook", "storage_queue", "service_bus_queue", "service_bus_topic", "eventhub", "azure_function"],
        sub.endpoint_type
      )
    ])
    error_message = "endpoint_type must be one of: webhook, storage_queue, service_bus_queue, service_bus_topic, eventhub, azure_function"
  }
}

variable "create_domain" {
  description = "Whether to create an Event Grid domain for multi-tenant scenarios"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "The name of the Event Grid domain. If not provided, a default name will be generated"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
