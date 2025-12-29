variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
}

variable "s3_key_prefix" {
  description = "S3 key prefix for CloudTrail logs"
  type        = string
  default     = null
}

variable "include_global_service_events" {
  description = "Whether to include global service events in the trail"
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Whether the trail is created in all regions"
  type        = bool
  default     = true
}

variable "is_organization_trail" {
  description = "Whether the trail is an organization trail"
  type        = bool
  default     = false
}

variable "enable_log_file_validation" {
  description = "Whether log file integrity validation is enabled"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encrypting CloudTrail logs"
  type        = string
  default     = null
}

variable "cloud_watch_logs_group_arn" {
  description = "CloudWatch Logs group ARN for CloudTrail logs"
  type        = string
  default     = null
}

variable "cloud_watch_logs_role_arn" {
  description = "IAM role ARN for CloudTrail to write to CloudWatch Logs"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Whether logging is enabled for the trail"
  type        = bool
  default     = true
}

variable "event_selectors" {
  description = "List of event selectors for data event logging"
  type = list(object({
    read_write_type           = string
    include_management_events = bool
    data_resources = optional(list(object({
      type   = string
      values = list(string)
    })), [])
  }))
  default = []
}

variable "insight_selectors" {
  description = "List of insight selectors for CloudTrail Insights"
  type = list(object({
    insight_type = string
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
