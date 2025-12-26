/**
 * Variables for GCP Observability Module
 */

# =============================================================================
# General Configuration
# =============================================================================

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "The GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test", "uat"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test, uat."
  }
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Notification Configuration
# =============================================================================

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Must be a valid email address."
  }
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications (optional)"
  type        = string
  default     = null
  sensitive   = true
}

variable "slack_channel_name" {
  description = "Slack channel name for notifications"
  type        = string
  default     = "#alerts"
}

variable "pagerduty_service_key" {
  description = "PagerDuty service key for notifications (optional)"
  type        = string
  default     = null
  sensitive   = true
}

# =============================================================================
# Log Sink Configuration
# =============================================================================

variable "enable_log_sink" {
  description = "Whether to create a log sink for exporting logs"
  type        = bool
  default     = true
}

variable "log_filter" {
  description = "Filter for the log sink to export specific logs"
  type        = string
  default     = "severity >= WARNING"
}

variable "log_sink_storage_class" {
  description = "Storage class for the log sink bucket"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.log_sink_storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs before deletion"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3650
    error_message = "Log retention must be between 1 and 3650 days."
  }
}

variable "log_archive_days" {
  description = "Number of days after which logs are moved to coldline storage"
  type        = number
  default     = 30

  validation {
    condition     = var.log_archive_days >= 1
    error_message = "Log archive days must be at least 1."
  }
}

variable "force_destroy_log_bucket" {
  description = "Force destroy the log bucket even if it contains objects"
  type        = bool
  default     = false
}

# =============================================================================
# Alert Configuration
# =============================================================================

variable "enable_alerts" {
  description = "Whether to enable alert policies"
  type        = bool
  default     = true
}

variable "cpu_threshold" {
  description = "CPU utilization threshold percentage for alerts"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_threshold > 0 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 1 and 100."
  }
}

variable "memory_threshold" {
  description = "Memory utilization threshold percentage for alerts"
  type        = number
  default     = 85

  validation {
    condition     = var.memory_threshold > 0 && var.memory_threshold <= 100
    error_message = "Memory threshold must be between 1 and 100."
  }
}

variable "error_log_threshold" {
  description = "Number of error log entries per minute to trigger an alert"
  type        = number
  default     = 10

  validation {
    condition     = var.error_log_threshold >= 1
    error_message = "Error log threshold must be at least 1."
  }
}

variable "alert_duration" {
  description = "Duration that conditions must be met before alerting (e.g., 60s, 300s)"
  type        = string
  default     = "300s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.alert_duration))
    error_message = "Alert duration must be specified in seconds (e.g., 60s, 300s)."
  }
}

# =============================================================================
# Uptime Check Configuration
# =============================================================================

variable "uptime_check_host" {
  description = "Hostname for uptime check (set to null to disable uptime checks)"
  type        = string
  default     = null
}

variable "uptime_check_path" {
  description = "Path for the uptime check HTTP request"
  type        = string
  default     = "/health"
}

variable "uptime_check_timeout" {
  description = "Timeout for uptime check in seconds"
  type        = string
  default     = "10s"
}

variable "uptime_check_period" {
  description = "How often the uptime check runs (60s, 300s, 600s, or 900s)"
  type        = string
  default     = "60s"

  validation {
    condition     = contains(["60s", "300s", "600s", "900s"], var.uptime_check_period)
    error_message = "Uptime check period must be one of: 60s, 300s, 600s, 900s."
  }
}

variable "uptime_check_content_match" {
  description = "Content to match in the uptime check response"
  type        = string
  default     = "ok"
}

variable "uptime_check_regions" {
  description = "Regions from which to run uptime checks"
  type        = list(string)
  default     = ["USA", "EUROPE", "ASIA_PACIFIC"]

  validation {
    condition     = length(var.uptime_check_regions) >= 1
    error_message = "At least one uptime check region must be specified."
  }
}

# =============================================================================
# Dashboard Configuration
# =============================================================================

variable "dashboard_display_name" {
  description = "Display name for the monitoring dashboard"
  type        = string
  default     = "Application Observability Dashboard"
}
