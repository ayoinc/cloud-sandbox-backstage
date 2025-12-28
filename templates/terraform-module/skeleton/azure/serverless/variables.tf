# -----------------------------------------------------------------------------
# Azure Serverless Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Core Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# -----------------------------------------------------------------------------
# Function App Configuration
# -----------------------------------------------------------------------------

variable "sku_name" {
  description = "SKU for the App Service Plan (Y1 = Consumption, EP1/EP2/EP3 = Elastic Premium, B1/B2/B3 = Basic, S1/S2/S3 = Standard)"
  type        = string
  default     = "Y1"

  validation {
    condition     = contains(["Y1", "EP1", "EP2", "EP3", "B1", "B2", "B3", "S1", "S2", "S3", "P1v2", "P2v2", "P3v2", "P1v3", "P2v3", "P3v3"], var.sku_name)
    error_message = "SKU name must be a valid App Service Plan SKU."
  }
}

variable "maximum_elastic_worker_count" {
  description = "Maximum number of workers for Elastic Premium plans"
  type        = number
  default     = 20
}

variable "runtime_stack" {
  description = "Runtime stack for the function app (python, node, java, dotnet)"
  type        = string
  default     = "python"

  validation {
    condition     = contains(["python", "node", "java", "dotnet"], var.runtime_stack)
    error_message = "Runtime stack must be one of: python, node, java, dotnet."
  }
}

variable "runtime_version" {
  description = "Version of the runtime stack (e.g., '3.11' for Python, '18' for Node, '17' for Java, '8.0' for .NET)"
  type        = string
  default     = "3.11"
}

variable "app_settings" {
  description = "Application settings for the function app"
  type        = map(string)
  default     = {}
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = []
}

variable "cors_support_credentials" {
  description = "Whether to support credentials in CORS requests"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check path for premium plans"
  type        = string
  default     = "/api/health"
}

# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------

variable "storage_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Storage replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration (optional)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Application Insights
# -----------------------------------------------------------------------------

variable "application_insights_connection_string" {
  description = "Connection string for existing Application Insights instance (if null, a new one is created)"
  type        = string
  default     = null
}

variable "application_insights_retention_days" {
  description = "Retention period in days for Application Insights (30, 60, 90, 120, 180, 270, 365, 550, 730)"
  type        = number
  default     = 30

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.application_insights_retention_days)
    error_message = "Application Insights retention must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730 days."
  }
}

# -----------------------------------------------------------------------------
# API Management Configuration
# -----------------------------------------------------------------------------

variable "enable_api_management" {
  description = "Enable Azure API Management"
  type        = bool
  default     = false
}

variable "apim_publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "API Publisher"
}

variable "apim_publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "api@example.com"
}

variable "apim_sku_name" {
  description = "SKU for API Management (Consumption, Developer, Basic, Standard, Premium)"
  type        = string
  default     = "Consumption_0"

  validation {
    condition     = can(regex("^(Consumption_0|Developer_1|Basic_[1-2]|Standard_[1-4]|Premium_[1-10])$", var.apim_sku_name))
    error_message = "API Management SKU must be in format: Consumption_0, Developer_1, Basic_1-2, Standard_1-4, or Premium_1-10."
  }
}

variable "apim_subnet_id" {
  description = "Subnet ID for API Management VNet integration (optional)"
  type        = string
  default     = null
}

variable "apim_api_path" {
  description = "API path prefix for API Management"
  type        = string
  default     = "v1"
}

variable "apim_subscription_required" {
  description = "Whether API subscription is required"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Service Bus Configuration
# -----------------------------------------------------------------------------

variable "enable_service_bus" {
  description = "Enable Azure Service Bus"
  type        = bool
  default     = false
}

variable "service_bus_sku" {
  description = "SKU for Service Bus namespace (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.service_bus_sku)
    error_message = "Service Bus SKU must be one of: Basic, Standard, Premium."
  }
}

variable "service_bus_capacity" {
  description = "Capacity for Premium Service Bus (1, 2, 4, 8, 16)"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 4, 8, 16], var.service_bus_capacity)
    error_message = "Service Bus capacity must be one of: 1, 2, 4, 8, 16."
  }
}

variable "service_bus_max_delivery_count" {
  description = "Maximum delivery count before moving to dead-letter queue"
  type        = number
  default     = 10
}

variable "service_bus_lock_duration" {
  description = "Lock duration for messages (ISO 8601 format)"
  type        = string
  default     = "PT1M"
}

variable "service_bus_max_size_mb" {
  description = "Maximum queue size in megabytes"
  type        = number
  default     = 1024
}

variable "service_bus_message_ttl" {
  description = "Default message time-to-live (ISO 8601 format)"
  type        = string
  default     = "P14D"
}

variable "service_bus_enable_partitioning" {
  description = "Enable partitioning for the queue (not available for Premium)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Event Grid Configuration
# -----------------------------------------------------------------------------

variable "enable_event_grid" {
  description = "Enable Azure Event Grid topic"
  type        = bool
  default     = false
}

variable "event_grid_public_access" {
  description = "Enable public network access for Event Grid"
  type        = bool
  default     = true
}

variable "event_grid_function_name" {
  description = "Name of the function to trigger from Event Grid"
  type        = string
  default     = "EventGridTrigger"
}

variable "event_grid_max_events_per_batch" {
  description = "Maximum number of events per batch for Event Grid subscription"
  type        = number
  default     = 1
}

variable "event_grid_preferred_batch_size_kb" {
  description = "Preferred batch size in kilobytes for Event Grid subscription"
  type        = number
  default     = 64
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
