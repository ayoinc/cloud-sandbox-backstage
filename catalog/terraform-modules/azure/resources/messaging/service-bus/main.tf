# -----------------------------------------------------------------------------
# Azure Service Bus Module
# -----------------------------------------------------------------------------
# Creates Service Bus namespace with queues, topics, and subscriptions
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the Service Bus namespace"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU tier (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  description = "Messaging units for Premium SKU (1, 2, 4, 8, 16)"
  type        = number
  default     = 0
}

variable "premium_messaging_partitions" {
  description = "Number of partitions for Premium SKU"
  type        = number
  default     = 0
}

variable "local_auth_enabled" {
  description = "Enable SAS authentication"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "zone_redundant" {
  description = "Enable zone redundancy (Premium only)"
  type        = bool
  default     = false
}

variable "identity" {
  description = "Managed identity configuration"
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}

variable "customer_managed_key" {
  description = "Customer managed key configuration"
  type = object({
    key_vault_key_id                  = string
    identity_id                       = string
    infrastructure_encryption_enabled = optional(bool, false)
  })
  default = null
}

variable "queues" {
  description = "Map of queues to create"
  type = map(object({
    max_delivery_count                      = optional(number, 10)
    max_size_in_megabytes                   = optional(number, 1024)
    default_message_ttl                     = optional(string)
    lock_duration                           = optional(string, "PT1M")
    dead_lettering_on_message_expiration    = optional(bool, false)
    requires_duplicate_detection            = optional(bool, false)
    duplicate_detection_history_time_window = optional(string)
    requires_session                        = optional(bool, false)
    enable_partitioning                     = optional(bool, false)
    enable_express                          = optional(bool, false)
    max_message_size_in_kilobytes           = optional(number)
    forward_to                              = optional(string)
    forward_dead_lettered_messages_to       = optional(string)
  }))
  default = {}
}

variable "topics" {
  description = "Map of topics to create"
  type = map(object({
    max_size_in_megabytes                   = optional(number, 1024)
    default_message_ttl                     = optional(string)
    requires_duplicate_detection            = optional(bool, false)
    duplicate_detection_history_time_window = optional(string)
    enable_partitioning                     = optional(bool, false)
    enable_express                          = optional(bool, false)
    max_message_size_in_kilobytes           = optional(number)
    support_ordering                        = optional(bool, false)
    enable_batched_operations               = optional(bool, true)
    subscriptions = optional(map(object({
      max_delivery_count                        = optional(number, 10)
      default_message_ttl                       = optional(string)
      lock_duration                             = optional(string, "PT1M")
      dead_lettering_on_message_expiration      = optional(bool, false)
      dead_lettering_on_filter_evaluation_error = optional(bool, true)
      requires_session                          = optional(bool, false)
      enable_batched_operations                 = optional(bool, true)
      forward_to                                = optional(string)
      forward_dead_lettered_messages_to         = optional(string)
    })), {})
  }))
  default = {}
}

variable "authorization_rules" {
  description = "Map of namespace-level authorization rules"
  type = map(object({
    listen = optional(bool, false)
    send   = optional(bool, false)
    manage = optional(bool, false)
  }))
  default = {}
}

variable "network_rule_set" {
  description = "Network rule set configuration"
  type = object({
    default_action                = optional(string, "Allow")
    public_network_access_enabled = optional(bool, true)
    trusted_services_allowed      = optional(bool, true)
    ip_rules                      = optional(list(string), [])
    virtual_network_rules = optional(list(object({
      subnet_id                            = string
      ignore_missing_vnet_service_endpoint = optional(bool, false)
    })), [])
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Service Bus Namespace
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_namespace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  capacity                      = var.sku == "Premium" ? var.capacity : null
  premium_messaging_partitions  = var.sku == "Premium" ? var.premium_messaging_partitions : null
  local_auth_enabled            = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = var.minimum_tls_version
  zone_redundant                = var.sku == "Premium" ? var.zone_redundant : null

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id                  = customer_managed_key.value.key_vault_key_id
      identity_id                       = customer_managed_key.value.identity_id
      infrastructure_encryption_enabled = customer_managed_key.value.infrastructure_encryption_enabled
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

# -----------------------------------------------------------------------------
# Network Rule Set
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_namespace_network_rule_set" "this" {
  count = var.network_rule_set != null && var.sku == "Premium" ? 1 : 0

  namespace_id                  = azurerm_servicebus_namespace.this.id
  default_action                = var.network_rule_set.default_action
  public_network_access_enabled = var.network_rule_set.public_network_access_enabled
  trusted_services_allowed      = var.network_rule_set.trusted_services_allowed
  ip_rules                      = var.network_rule_set.ip_rules

  dynamic "network_rules" {
    for_each = var.network_rule_set.virtual_network_rules
    content {
      subnet_id                            = network_rules.value.subnet_id
      ignore_missing_vnet_service_endpoint = network_rules.value.ignore_missing_vnet_service_endpoint
    }
  }
}

# -----------------------------------------------------------------------------
# Authorization Rules
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_namespace_authorization_rule" "this" {
  for_each = var.authorization_rules

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id
  listen       = each.value.listen
  send         = each.value.send
  manage       = each.value.manage
}

# -----------------------------------------------------------------------------
# Queues
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_queue" "this" {
  for_each = var.queues

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id

  max_delivery_count                      = each.value.max_delivery_count
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  default_message_ttl                     = each.value.default_message_ttl
  lock_duration                           = each.value.lock_duration
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  requires_session                        = each.value.requires_session
  enable_partitioning                     = var.sku != "Premium" ? each.value.enable_partitioning : false
  enable_express                          = var.sku != "Premium" ? each.value.enable_express : false
  max_message_size_in_kilobytes           = var.sku == "Premium" ? each.value.max_message_size_in_kilobytes : null
  forward_to                              = each.value.forward_to
  forward_dead_lettered_messages_to       = each.value.forward_dead_lettered_messages_to
}

# -----------------------------------------------------------------------------
# Topics
# -----------------------------------------------------------------------------

resource "azurerm_servicebus_topic" "this" {
  for_each = var.sku != "Basic" ? var.topics : {}

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id

  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  default_message_ttl                     = each.value.default_message_ttl
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  enable_partitioning                     = var.sku != "Premium" ? each.value.enable_partitioning : false
  enable_express                          = var.sku != "Premium" ? each.value.enable_express : false
  max_message_size_in_kilobytes           = var.sku == "Premium" ? each.value.max_message_size_in_kilobytes : null
  support_ordering                        = each.value.support_ordering
  enable_batched_operations               = each.value.enable_batched_operations
}

# -----------------------------------------------------------------------------
# Subscriptions
# -----------------------------------------------------------------------------

locals {
  subscriptions = flatten([
    for topic_name, topic in var.topics : [
      for sub_name, sub in topic.subscriptions : {
        key        = "${topic_name}-${sub_name}"
        topic_name = topic_name
        sub_name   = sub_name
        config     = sub
      }
    ]
  ])
}

resource "azurerm_servicebus_subscription" "this" {
  for_each = var.sku != "Basic" ? { for sub in local.subscriptions : sub.key => sub } : {}

  name     = each.value.sub_name
  topic_id = azurerm_servicebus_topic.this[each.value.topic_name].id

  max_delivery_count                        = each.value.config.max_delivery_count
  default_message_ttl                       = each.value.config.default_message_ttl
  lock_duration                             = each.value.config.lock_duration
  dead_lettering_on_message_expiration      = each.value.config.dead_lettering_on_message_expiration
  dead_lettering_on_filter_evaluation_error = each.value.config.dead_lettering_on_filter_evaluation_error
  requires_session                          = each.value.config.requires_session
  enable_batched_operations                 = each.value.config.enable_batched_operations
  forward_to                                = each.value.config.forward_to
  forward_dead_lettered_messages_to         = each.value.config.forward_dead_lettered_messages_to
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.name
}

output "default_primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_servicebus_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "default_primary_key" {
  description = "Primary key"
  value       = azurerm_servicebus_namespace.this.default_primary_key
  sensitive   = true
}

output "endpoint" {
  description = "Endpoint URL"
  value       = azurerm_servicebus_namespace.this.endpoint
}

output "queue_ids" {
  description = "Map of queue IDs"
  value       = { for k, v in azurerm_servicebus_queue.this : k => v.id }
}

output "topic_ids" {
  description = "Map of topic IDs"
  value       = { for k, v in azurerm_servicebus_topic.this : k => v.id }
}
