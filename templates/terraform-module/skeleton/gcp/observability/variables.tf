variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.project_name))
    error_message = "project_name must start with a lowercase letter and contain only lowercase letters, digits and hyphens (max 63 characters)."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,7}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits and start with a letter."
  }
}

variable "project_id" {
  description = "ID of the Google Cloud project that owns the resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID (6-30 lowercase letters, digits or hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region for regional resources."
  type        = string
}

variable "labels" {
  description = "Labels applied to every resource that supports them."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "notification_email" {
  description = "Email address that receives alert notifications. Null creates no email channel."
  type        = string
  default     = null

  validation {
    condition     = var.notification_email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.notification_email))
    error_message = "notification_email must be a valid email address."
  }
}

variable "slack_channel_name" {
  description = "Slack channel that receives alert notifications, including the leading #. Used when slack_auth_token is set."
  type        = string
  default     = "#alerts"

  validation {
    condition     = can(regex("^#.+", var.slack_channel_name))
    error_message = "slack_channel_name must start with #."
  }
}

variable "slack_auth_token" {
  description = "OAuth token of the Google Cloud Monitoring Slack app. Null creates no Slack channel."
  type        = string
  default     = null
  sensitive   = true
}

variable "pagerduty_service_key" {
  description = "PagerDuty integration key. Null creates no PagerDuty channel."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_log_sink" {
  description = "Archive log entries matching log_filter to a Cloud Storage bucket."
  type        = bool
  default     = true
}

variable "log_filter" {
  description = "Logging query selecting the entries that are archived."
  type        = string
  default     = "severity>=WARNING"

  validation {
    condition     = length(trimspace(var.log_filter)) > 0
    error_message = "log_filter must not be empty."
  }
}

variable "log_archive_days" {
  description = "Age in days after which archived logs move to Coldline storage."
  type        = number
  default     = 30

  validation {
    condition     = var.log_archive_days >= 1
    error_message = "log_archive_days must be at least 1."
  }
}

variable "log_retention_days" {
  description = "Age in days after which archived logs are deleted. Must be greater than log_archive_days."
  type        = number
  default     = 365

  validation {
    condition     = var.log_retention_days >= 2
    error_message = "log_retention_days must be at least 2."
  }
}

variable "force_destroy_log_bucket" {
  description = "Delete archived logs when the bucket is destroyed."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "ID of a Cloud KMS key that encrypts the log bucket. The Cloud Storage service agent must be allowed to use it. Null uses Google-managed encryption."
  type        = string
  default     = null
}

variable "enable_alerts" {
  description = "Create the CPU, memory, error log and uptime alert policies."
  type        = bool
  default     = true
}

variable "cpu_threshold_percent" {
  description = "VM CPU utilization in percent above which the CPU alert fires."
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_threshold_percent > 0 && var.cpu_threshold_percent <= 100
    error_message = "cpu_threshold_percent must be greater than 0 and at most 100."
  }
}

variable "memory_threshold_percent" {
  description = "VM memory use in percent above which the memory alert fires. Requires the Ops Agent on the VMs."
  type        = number
  default     = 85

  validation {
    condition     = var.memory_threshold_percent > 0 && var.memory_threshold_percent <= 100
    error_message = "memory_threshold_percent must be greater than 0 and at most 100."
  }
}

variable "alert_duration_seconds" {
  description = "Seconds a threshold must be exceeded before an alert fires. A multiple of 60."
  type        = number
  default     = 300

  validation {
    condition     = var.alert_duration_seconds >= 60 && var.alert_duration_seconds % 60 == 0
    error_message = "alert_duration_seconds must be a multiple of 60 and at least 60."
  }
}

variable "error_log_notification_period_seconds" {
  description = "Minimum seconds between two notifications of the error log alert."
  type        = number
  default     = 300

  validation {
    condition     = var.error_log_notification_period_seconds >= 300
    error_message = "error_log_notification_period_seconds must be at least 300."
  }
}

variable "uptime_check_host" {
  description = "Host name probed over HTTPS from several regions. Null creates no uptime check."
  type        = string
  default     = null

  validation {
    condition     = var.uptime_check_host == null || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$", var.uptime_check_host))
    error_message = "uptime_check_host must be a host name without scheme or path."
  }
}

variable "uptime_check_path" {
  description = "Path requested by the uptime check."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.uptime_check_path, "/")
    error_message = "uptime_check_path must start with a slash."
  }
}

variable "uptime_check_period_seconds" {
  description = "Seconds between uptime probes: 60, 300, 600 or 900."
  type        = number
  default     = 60

  validation {
    condition     = contains([60, 300, 600, 900], var.uptime_check_period_seconds)
    error_message = "uptime_check_period_seconds must be 60, 300, 600 or 900."
  }
}

variable "uptime_check_timeout_seconds" {
  description = "Seconds after which an uptime probe counts as failed, 1 to 60."
  type        = number
  default     = 10

  validation {
    condition     = var.uptime_check_timeout_seconds >= 1 && var.uptime_check_timeout_seconds <= 60
    error_message = "uptime_check_timeout_seconds must be between 1 and 60."
  }
}

variable "enable_dashboard" {
  description = "Create a Cloud Monitoring dashboard with VM, error and uptime charts."
  type        = bool
  default     = true
}

variable "dashboard_display_name" {
  description = "Title of the dashboard. Null derives it from the project name and environment."
  type        = string
  default     = null
}
