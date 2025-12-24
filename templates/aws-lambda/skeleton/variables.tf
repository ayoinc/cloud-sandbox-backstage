# =============================================================================
# AWS Lambda - Root Variables
# =============================================================================
# Input variables for the root module. Values are provided via tfvars files
# in the environments/ directory.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.12, nodejs22.x, java21)"
  type        = string
}

variable "handler" {
  description = "Lambda function handler (e.g., main.handler, index.handler)"
  type        = string
}

# -----------------------------------------------------------------------------
# Optional Configuration
# -----------------------------------------------------------------------------
variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Lambda function"
}

variable "memory_size" {
  description = "Amount of memory in MB for the function (128-10240)"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Function timeout in seconds (1-900)"
  type        = number
  default     = 30
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions (0 to disable, -1 for unreserved)"
  type        = number
  default     = -1
}

variable "publish_version" {
  description = "Whether to publish a new version on each update"
  type        = bool
  default     = true
}

variable "architectures" {
  description = "Instruction set architecture (x86_64 or arm64)"
  type        = list(string)
  default     = ["x86_64"]
}

variable "ephemeral_storage_size" {
  description = "Size of ephemeral storage (/tmp) in MB (512-10240)"
  type        = number
  default     = 512
}

variable "layers" {
  description = "List of Lambda Layer ARNs to attach"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------
variable "environment_variables" {
  description = "Map of environment variables for the function"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------
variable "vpc_subnet_ids" {
  description = "List of VPC subnet IDs for Lambda"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs for Lambda"
  type        = list(string)
  default     = null
}

# -----------------------------------------------------------------------------
# Dead Letter Queue
# -----------------------------------------------------------------------------
variable "dead_letter_target_arn" {
  description = "ARN of SNS topic or SQS queue for dead letter queue"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Tracing
# -----------------------------------------------------------------------------
variable "tracing_mode" {
  description = "X-Ray tracing mode (Active or PassThrough)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "log_kms_key_id" {
  description = "KMS key ARN for log encryption"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------
variable "custom_iam_policy" {
  description = "Custom IAM policy document (JSON)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Alias Configuration
# -----------------------------------------------------------------------------
variable "create_alias" {
  description = "Whether to create a 'live' alias"
  type        = bool
  default     = true
}

variable "alias_routing_config" {
  description = "Traffic routing config for canary deployments"
  type        = map(number)
  default     = null
}

# -----------------------------------------------------------------------------
# Function URL
# -----------------------------------------------------------------------------
variable "create_function_url" {
  description = "Whether to create a Lambda function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Authorization type for function URL (AWS_IAM or NONE)"
  type        = string
  default     = "AWS_IAM"
}

variable "function_url_cors" {
  description = "CORS configuration for function URL"
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["*"])
    allow_origins     = optional(list(string), ["*"])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 0)
  })
  default = null
}

# -----------------------------------------------------------------------------
# Monitoring & Alarms
# -----------------------------------------------------------------------------
variable "create_error_alarm" {
  description = "Whether to create CloudWatch alarm for errors"
  type        = bool
  default     = false
}

variable "error_alarm_threshold" {
  description = "Error count threshold for alarm"
  type        = number
  default     = 1
}

variable "create_duration_alarm" {
  description = "Whether to create CloudWatch alarm for duration"
  type        = bool
  default     = false
}

variable "duration_alarm_threshold" {
  description = "Duration threshold in milliseconds for alarm"
  type        = number
  default     = 5000
}

variable "create_throttle_alarm" {
  description = "Whether to create CloudWatch alarm for throttles"
  type        = bool
  default     = false
}

variable "throttle_alarm_threshold" {
  description = "Throttle count threshold for alarm"
  type        = number
  default     = 1
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
