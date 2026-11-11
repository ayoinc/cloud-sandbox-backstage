# -----------------------------------------------------------------------------
# AWS Serverless Module - Variables
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
  description = "KMS key ARN used to encrypt environment variables, log groups (its key policy must allow CloudWatch Logs) and queues. Null uses the AWS managed keys"
  type        = string
  default     = null
}

# Network Configuration
variable "enable_vpc" {
  description = "Attach the function to a VPC. Requires vpc_id and subnet_ids"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_vpc || (var.vpc_id != null && length(var.subnet_ids) > 0)
    error_message = "vpc_id and at least one entry in subnet_ids must be set when enable_vpc is true."
  }
}

variable "vpc_id" {
  description = "VPC ID the function's security group is created in. Required when enable_vpc is true"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Private subnet IDs the function is attached to when enable_vpc is true"
  type        = list(string)
  default     = []
}

# Lambda Configuration
variable "package_type" {
  description = "Zip deploys deployment_package, or the built-in handler in src/ when none is given. Image deploys image_uri"
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be Zip or Image."
  }

  validation {
    condition     = var.package_type != "Image" || var.image_uri != null
    error_message = "image_uri must be set when package_type is Image."
  }
}

variable "deployment_package" {
  description = "Path to a zip deployment package. Null deploys the built-in handler from the module's src directory"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI of the function. Only used when package_type is Image"
  type        = string
  default     = null
}

variable "runtime" {
  description = "Lambda runtime for Zip packages. The built-in handler needs a Python runtime"
  type        = string
  default     = "python3.13"
}

variable "handler" {
  description = "Lambda handler for Zip packages"
  type        = string
  default     = "handler.main"
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "environment_variables" {
  description = "Lambda environment variables, merged with ENVIRONMENT and PROJECT"
  type        = map(string)
  default     = {}
}

variable "reserved_concurrency" {
  description = "Reserved concurrent executions (-1 means unreserved)"
  type        = number
  default     = -1
}

variable "provisioned_concurrency" {
  description = "Provisioned concurrency on the live alias (0 disables it)"
  type        = number
  default     = 0
}

variable "enable_xray" {
  description = "Enable active X-Ray tracing"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention in days of the function and API log groups"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

# API Gateway Configuration
variable "enable_api_gateway" {
  description = "Publish the function through an API Gateway HTTP API"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "Origins allowed by CORS. Credentials are only allowed when no wildcard origin is listed"
  type        = list(string)
  default     = ["*"]
}

variable "api_throttle_burst" {
  description = "API throttle burst limit (requests)"
  type        = number
  default     = 100
}

variable "api_throttle_rate" {
  description = "API throttle steady-state rate limit (requests per second)"
  type        = number
  default     = 50
}

# EventBridge Schedule
variable "schedule_expression" {
  description = "EventBridge schedule (cron(...) or rate(...)) that invokes the function. Null creates no schedule"
  type        = string
  default     = null

  validation {
    condition     = var.schedule_expression == null || can(regex("^(rate|cron)\\(.+\\)$", coalesce(var.schedule_expression, "rate(1 day)")))
    error_message = "schedule_expression must be a rate(...) or cron(...) expression."
  }
}

# SQS Configuration
variable "enable_sqs" {
  description = "Create an SQS queue that triggers the function"
  type        = bool
  default     = false
}

variable "enable_dlq" {
  description = "Create a dead-letter queue for the SQS queue"
  type        = bool
  default     = true
}

variable "sqs_batch_size" {
  description = "Maximum number of messages per invocation"
  type        = number
  default     = 10

  validation {
    condition     = var.sqs_batch_size >= 1 && var.sqs_batch_size <= 10
    error_message = "sqs_batch_size must be between 1 and 10."
  }
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
