# -----------------------------------------------------------------------------
# Azure Observability Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 2-40 characters of lowercase letters, numbers and hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.environment))
    error_message = "Environment must be 2-12 lowercase letters or numbers and start with a letter."
  }
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
# Log Analytics Workspace Configuration
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics workspace"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention days must be between 30 and 730."
  }
}

variable "sku" {
  description = "SKU of the Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["PerGB2018", "CapacityReservation"], var.sku)
    error_message = "SKU must be PerGB2018 or CapacityReservation (the legacy tiers cannot be selected for new workspaces)."
  }
}

variable "daily_quota_gb" {
  description = "Daily quota in GB for Log Analytics (-1 for unlimited)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Enable internet ingestion for Log Analytics"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable internet query for Log Analytics"
  type        = bool
  default     = true
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Reservation capacity in GB per day (required for the CapacityReservation SKU)"
  type        = number
  default     = null

  validation {
    condition     = var.reservation_capacity_in_gb_per_day == null || contains([100, 200, 300, 400, 500, 1000, 2000, 5000, 10000, 25000, 50000], coalesce(var.reservation_capacity_in_gb_per_day, 100))
    error_message = "Reservation capacity must be one of: 100, 200, 300, 400, 500, 1000, 2000, 5000, 10000, 25000, 50000."
  }
}

# -----------------------------------------------------------------------------
# Application Insights Configuration
# -----------------------------------------------------------------------------

variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = true
}

variable "application_insights_type" {
  description = "Type of Application Insights"
  type        = string
  default     = "web"

  validation {
    condition     = contains(["ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store", "web"], var.application_insights_type)
    error_message = "Application type must be one of: ios, java, MobileCenter, Node.JS, other, phone, store, web."
  }
}

variable "application_insights_retention_days" {
  description = "Number of days to retain Application Insights data"
  type        = number
  default     = 90

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.application_insights_retention_days)
    error_message = "Application Insights retention days must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730."
  }
}

variable "application_insights_daily_cap_gb" {
  description = "Daily data cap in GB for Application Insights (null for the service default)"
  type        = number
  default     = null
}

variable "application_insights_disable_cap_notifications" {
  description = "Disable daily cap notifications"
  type        = bool
  default     = false
}

variable "application_insights_sampling_percentage" {
  description = "Sampling percentage for Application Insights (0-100)"
  type        = number
  default     = 100

  validation {
    condition     = var.application_insights_sampling_percentage >= 0 && var.application_insights_sampling_percentage <= 100
    error_message = "Sampling percentage must be between 0 and 100."
  }
}

variable "application_insights_disable_ip_masking" {
  description = "Disable IP masking in Application Insights"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Container Insights Configuration
# -----------------------------------------------------------------------------

variable "enable_container_insights" {
  description = "Enable Container Insights solution"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Alert Configuration
# -----------------------------------------------------------------------------

variable "alert_email" {
  description = "Primary email address for alerts"
  type        = string
  default     = null
}

variable "additional_alert_emails" {
  description = "Additional email addresses for alerts"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "alert_sms_receivers" {
  description = "SMS receivers for alerts"
  type = list(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  nullable = false
  default  = []
}

variable "alert_webhook_urls" {
  description = "Webhook URLs for alert notifications"
  type        = list(string)
  nullable    = false
  default     = []

  validation {
    condition     = alltrue([for url in var.alert_webhook_urls : startswith(url, "https://")])
    error_message = "Webhook URLs must use https."
  }
}

variable "azure_app_push_receivers" {
  description = "Azure app push notification receivers"
  type = list(object({
    name          = string
    email_address = string
  }))
  nullable = false
  default  = []
}

variable "alert_frequency" {
  description = "Frequency of alert evaluation"
  type        = string
  default     = "PT5M"

  validation {
    condition     = contains(["PT1M", "PT5M", "PT15M", "PT30M", "PT1H"], var.alert_frequency)
    error_message = "Alert frequency must be one of: PT1M, PT5M, PT15M, PT30M, PT1H."
  }
}

variable "alert_window_size" {
  description = "Time window for alert evaluation (must not be shorter than alert_frequency)"
  type        = string
  default     = "PT15M"

  validation {
    condition     = contains(["PT5M", "PT15M", "PT30M", "PT1H", "PT6H", "P1D"], var.alert_window_size)
    error_message = "Alert window size must be one of: PT5M, PT15M, PT30M, PT1H, PT6H, P1D."
  }

  validation {
    condition = (
      lookup({ PT5M = 5, PT15M = 15, PT30M = 30, PT1H = 60, PT6H = 360, P1D = 1440 }, var.alert_window_size, 0) >=
      lookup({ PT1M = 1, PT5M = 5, PT15M = 15, PT30M = 30, PT1H = 60 }, var.alert_frequency, 0)
    )
    error_message = "Alert window size must not be shorter than alert_frequency."
  }
}

# -----------------------------------------------------------------------------
# Monitored Resource Configuration
# -----------------------------------------------------------------------------

variable "monitored_resource_id" {
  description = "Resource ID of the virtual machine or scale set watched by the CPU and memory alerts. Null creates neither alert. The value must be known at plan time"
  type        = string
  default     = null
}

variable "http_monitored_resource_id" {
  description = "Resource ID of the App Service or Function App watched by the HTTP errors alert. Null creates no alert. The value must be known at plan time"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# CPU Alert Configuration
# -----------------------------------------------------------------------------

variable "enable_cpu_alert" {
  description = "Enable CPU usage alert on monitored_resource_id"
  type        = bool
  default     = true
}

variable "cpu_threshold" {
  description = "CPU percentage threshold for alerts"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_threshold >= 0 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 0 and 100."
  }
}

variable "cpu_alert_severity" {
  description = "Severity of CPU alert (0-4, where 0 is most severe)"
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_alert_severity >= 0 && var.cpu_alert_severity <= 4
    error_message = "Alert severity must be between 0 and 4."
  }
}

variable "cpu_metric_namespace" {
  description = "Metric namespace for CPU metrics. Null uses the resource type of monitored_resource_id"
  type        = string
  default     = null
}

variable "cpu_metric_name" {
  description = "Metric name for CPU usage"
  type        = string
  default     = "Percentage CPU"
}

# -----------------------------------------------------------------------------
# Memory Alert Configuration
# -----------------------------------------------------------------------------

variable "enable_memory_alert" {
  description = "Enable memory usage alert on monitored_resource_id"
  type        = bool
  default     = true
}

variable "memory_threshold" {
  description = "Memory usage percentage threshold for alerts"
  type        = number
  default     = 85

  validation {
    condition     = var.memory_threshold >= 0 && var.memory_threshold <= 100
    error_message = "Memory threshold must be between 0 and 100."
  }
}

variable "memory_alert_severity" {
  description = "Severity of memory alert (0-4)"
  type        = number
  default     = 2

  validation {
    condition     = var.memory_alert_severity >= 0 && var.memory_alert_severity <= 4
    error_message = "Alert severity must be between 0 and 4."
  }
}

variable "memory_metric_namespace" {
  description = "Metric namespace for memory metrics. Null uses the resource type of monitored_resource_id"
  type        = string
  default     = null
}

variable "memory_metric_name" {
  description = "Metric reporting the percentage of memory still available; the alert fires when it drops below 100 - memory_threshold"
  type        = string
  default     = "Available Memory Percentage"
}

# -----------------------------------------------------------------------------
# Disk Alert Configuration
# -----------------------------------------------------------------------------

variable "enable_disk_alert" {
  description = "Enable the disk usage alert for every machine that reports VM insights data to the workspace"
  type        = bool
  default     = true
}

variable "disk_threshold" {
  description = "Disk usage percentage threshold for alerts"
  type        = number
  default     = 90

  validation {
    condition     = var.disk_threshold >= 0 && var.disk_threshold <= 100
    error_message = "Disk threshold must be between 0 and 100."
  }
}

variable "disk_alert_severity" {
  description = "Severity of disk alert (0-4)"
  type        = number
  default     = 2

  validation {
    condition     = var.disk_alert_severity >= 0 && var.disk_alert_severity <= 4
    error_message = "Alert severity must be between 0 and 4."
  }
}

# -----------------------------------------------------------------------------
# HTTP Errors Alert Configuration
# -----------------------------------------------------------------------------

variable "enable_http_errors_alert" {
  description = "Enable HTTP 5xx errors alert on http_monitored_resource_id"
  type        = bool
  default     = true
}

variable "http_errors_threshold" {
  description = "HTTP 5xx errors count threshold for alerts"
  type        = number
  default     = 10

  validation {
    condition     = var.http_errors_threshold >= 0
    error_message = "HTTP errors threshold must be non-negative."
  }
}

variable "http_errors_alert_severity" {
  description = "Severity of HTTP errors alert (0-4)"
  type        = number
  default     = 1

  validation {
    condition     = var.http_errors_alert_severity >= 0 && var.http_errors_alert_severity <= 4
    error_message = "Alert severity must be between 0 and 4."
  }
}

variable "http_errors_metric_namespace" {
  description = "Metric namespace for HTTP error metrics. Null uses the resource type of http_monitored_resource_id"
  type        = string
  default     = null
}

variable "http_errors_metric_name" {
  description = "Metric name for HTTP 5xx errors"
  type        = string
  default     = "Http5xx"
}

# -----------------------------------------------------------------------------
# Service Health Alert Configuration
# -----------------------------------------------------------------------------

variable "enable_service_health_alert" {
  description = "Enable Azure Service Health alerts"
  type        = bool
  default     = true
}

variable "service_health_events" {
  description = "Service health event types to alert on"
  type        = list(string)
  nullable    = false
  default     = ["Incident", "Maintenance", "Security"]

  validation {
    condition = length(var.service_health_events) > 0 && alltrue([
      for event in var.service_health_events : contains(["ActionRequired", "Incident", "Maintenance", "Informational", "Security"], event)
    ])
    error_message = "Provide at least one service health event out of: ActionRequired, Incident, Maintenance, Informational, Security."
  }
}

variable "service_health_locations" {
  description = "Locations to monitor for service health (empty for all)"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "service_health_services" {
  description = "Azure services to monitor for health (empty for all)"
  type        = list(string)
  nullable    = false
  default     = []
}

# -----------------------------------------------------------------------------
# Dashboard Configuration
# -----------------------------------------------------------------------------

variable "enable_dashboard" {
  description = "Enable Azure Portal dashboard"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Diagnostic Settings Configuration
# -----------------------------------------------------------------------------

variable "diagnostic_setting_resource_id" {
  description = "ID of an existing resource whose logs and metrics are sent to the workspace. Null creates no diagnostic setting. The value must be known at plan time"
  type        = string
  default     = null
}

variable "diagnostic_log_category_groups" {
  description = "Log category groups to collect from diagnostic_setting_resource_id"
  type        = list(string)
  nullable    = false
  default     = ["allLogs"]
}

variable "diagnostic_log_categories" {
  description = "Individual log categories to collect from diagnostic_setting_resource_id, for resources without category groups"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "diagnostic_metric_categories" {
  description = "Metric categories to collect from diagnostic_setting_resource_id"
  type        = list(string)
  nullable    = false
  default     = ["AllMetrics"]
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  nullable    = false
  default     = {}
}
