# =============================================================================
# AWS Lambda Module - Variables
# =============================================================================
# Input variables for the Lambda module.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the Lambda function"
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "Function name must be between 1 and 64 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "development", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be dev, development, staging, prod, or production."
  }
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.12, nodejs22.x, java21)"
  type        = string

  validation {
    condition     = can(regex("^(python3\\.(9|10|11|12)|nodejs(18|20|22)\\.x|java(11|17|21)|go1\\.x|ruby3\\.2|dotnet(6|8)|provided(\\.al2023)?)$", var.runtime))
    error_message = "Invalid Lambda runtime specified."
  }
}

variable "handler" {
  description = "Lambda function handler (e.g., main.handler, index.handler)"
  type        = string
}

# -----------------------------------------------------------------------------
# Function Package Configuration
# -----------------------------------------------------------------------------
variable "filename" {
  description = "Path to the function's deployment package (mutually exclusive with s3_bucket)"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the package file (for updates)"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the function's deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version of the function's deployment package"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Optional Configuration
# -----------------------------------------------------------------------------
variable "name_prefix" {
  description = "Prefix for the function name (e.g., org name)"
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Lambda function"
}

variable "memory_size" {
  description = "Amount of memory in MB for the function (128-10240)"
  type        = number
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 MB and 10,240 MB."
  }
}

variable "timeout" {
  description = "Function timeout in seconds (1-900)"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions (0 to disable, -1 for unreserved)"
  type        = number
  default     = -1

  validation {
    condition     = var.reserved_concurrent_executions >= -1
    error_message = "Reserved concurrent executions must be -1 (unreserved) or >= 0."
  }
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

  validation {
    condition     = alltrue([for a in var.architectures : contains(["x86_64", "arm64"], a)])
    error_message = "Architecture must be x86_64 or arm64."
  }
}

variable "ephemeral_storage_size" {
  description = "Size of ephemeral storage (/tmp) in MB (512-10240)"
  type        = number
  default     = 512

  validation {
    condition     = var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240
    error_message = "Ephemeral storage must be between 512 MB and 10,240 MB."
  }
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

  validation {
    condition     = var.tracing_mode == null || contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "Tracing mode must be Active or PassThrough."
  }
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096,
      1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
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

  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url_auth_type)
    error_message = "Function URL auth type must be AWS_IAM or NONE."
  }
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
