# -----------------------------------------------------------------------------
# AWS Observability Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

# Log Configuration
variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "security_log_retention_days" {
  description = "Security log retention in days"
  type        = number
  default     = 365
}

# Dashboard Configuration
variable "enable_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = true
}

# Alarm Configuration
variable "enable_alarms" {
  description = "Create CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email for alarm notifications"
  type        = string
  default     = ""
}

variable "cpu_alarm_threshold" {
  description = "CPU alarm threshold percentage"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory alarm threshold percentage"
  type        = number
  default     = 80
}

variable "rds_cpu_alarm_threshold" {
  description = "RDS CPU alarm threshold percentage"
  type        = number
  default     = 80
}

variable "rds_storage_alarm_threshold" {
  description = "RDS free storage alarm threshold in GB"
  type        = number
  default     = 10
}

variable "error_log_threshold" {
  description = "Error count threshold per 5 minutes"
  type        = number
  default     = 10
}

# X-Ray Configuration
variable "enable_xray" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
