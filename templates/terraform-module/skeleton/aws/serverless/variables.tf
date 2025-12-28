# -----------------------------------------------------------------------------
# AWS Serverless Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (for VPC-enabled Lambda)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for Lambda"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

# Lambda Configuration
variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "handler.main"
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "deployment_package" {
  description = "Path to deployment package (zip)"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "Container image URI"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Lambda environment variables"
  type        = map(string)
  default     = {}
}

variable "reserved_concurrency" {
  description = "Reserved concurrent executions"
  type        = number
  default     = -1
}

variable "provisioned_concurrency" {
  description = "Provisioned concurrency"
  type        = number
  default     = 0
}

variable "enable_xray" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# API Gateway Configuration
variable "enable_api_gateway" {
  description = "Create API Gateway"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "api_throttle_burst" {
  description = "API throttle burst limit"
  type        = number
  default     = 100
}

variable "api_throttle_rate" {
  description = "API throttle rate limit"
  type        = number
  default     = 50
}

# EventBridge Schedule
variable "schedule_expression" {
  description = "Schedule expression (cron or rate)"
  type        = string
  default     = null
}

# SQS Configuration
variable "enable_sqs" {
  description = "Create SQS queue"
  type        = bool
  default     = false
}

variable "enable_dlq" {
  description = "Create dead-letter queue"
  type        = bool
  default     = true
}

variable "sqs_batch_size" {
  description = "SQS batch size"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
