# -----------------------------------------------------------------------------
# AWS Observability Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as the prefix of every resource name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9._-]*$", var.project_name))
    error_message = "project_name must start with a letter and contain only letters, digits, dots, underscores and hyphens."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,8}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the log groups and the alarm topic. Its key policy must allow CloudWatch Logs and CloudWatch alarms (the security module's key does). Null leaves the log groups on the CloudWatch Logs service key and the topic without server-side encryption"
  type        = string
  default     = null
}

# Log Configuration
variable "log_retention_days" {
  description = "Retention in days of the application and system log groups"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "security_log_retention_days" {
  description = "Retention in days of the security log group"
  type        = number
  default     = 365

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.security_log_retention_days)
    error_message = "security_log_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

# Monitored resources
variable "autoscaling_group_name" {
  description = "Auto Scaling group shown on the dashboard and watched by the CPU and memory alarms. Null uses the compute module's name (<project>-<environment>-asg)"
  type        = string
  default     = null
}

variable "db_instance_identifier" {
  description = "RDS instance shown on the dashboard and watched by the database alarms. Null uses the database module's name (<project>-<environment>-db)"
  type        = string
  default     = null
}

# Dashboard Configuration
variable "enable_dashboard" {
  description = "Create the CloudWatch dashboard"
  type        = bool
  default     = true
}

# Alarm Configuration
variable "enable_alarms" {
  description = "Create the CloudWatch alarms and their SNS topic"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address subscribed to the alarm topic (the recipient must confirm the subscription). Empty or null creates no subscription"
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
  description = "Application log error count per 5 minutes that raises the alarm"
  type        = number
  default     = 10
}

# X-Ray Configuration
variable "enable_xray" {
  description = "Create an X-Ray sampling rule for the project's services"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
