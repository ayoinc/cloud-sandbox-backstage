variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "namespace_name" {
  description = "Name of the Event Hub namespace"
  type        = string
}

variable "sku" {
  description = "SKU for the Event Hub namespace (Basic, Standard, or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be one of: Basic, Standard, Premium."
  }
}

variable "capacity" {
  description = "Throughput units for the namespace (1-20 for Standard, 1-4 for Premium)"
  type        = number
  default     = 1

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 20
    error_message = "Capacity must be between 1 and 20."
  }
}

variable "auto_inflate_enabled" {
  description = "Enable auto-inflate for the namespace"
  type        = bool
  default     = false
}

variable "maximum_throughput_units" {
  description = "Maximum throughput units when auto-inflate is enabled"
  type        = number
  default     = 20

  validation {
    condition     = var.maximum_throughput_units >= 1 && var.maximum_throughput_units <= 40
    error_message = "Maximum throughput units must be between 1 and 40."
  }
}

variable "zone_redundant" {
  description = "Enable zone redundancy for the namespace"
  type        = bool
  default     = false
}

variable "eventhubs" {
  description = "List of Event Hubs to create"
  type = list(object({
    name                       = string
    partition_count            = number
    message_retention          = number
    capture_enabled            = bool
    capture_storage_account_id = optional(string)
    capture_container_name     = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for eh in var.eventhubs : eh.partition_count >= 1 && eh.partition_count <= 32
    ])
    error_message = "Partition count must be between 1 and 32."
  }

  validation {
    condition = alltrue([
      for eh in var.eventhubs : eh.message_retention >= 1 && eh.message_retention <= 7
    ])
    error_message = "Message retention must be between 1 and 7 days."
  }
}

variable "consumer_groups" {
  description = "List of consumer groups to create"
  type = list(object({
    eventhub_name = string
    name          = string
  }))
  default = []
}

variable "authorization_rules" {
  description = "List of authorization rules to create"
  type = list(object({
    name   = string
    listen = bool
    send   = bool
    manage = bool
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
