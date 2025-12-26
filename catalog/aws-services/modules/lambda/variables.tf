################################################################################
# Lambda Function Variables
################################################################################

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 128
}

variable "package_type" {
  description = "Package type (Zip or Image)"
  type        = string
  default     = "Zip"
}

variable "filename" {
  description = "Path to the Lambda deployment package"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the package"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version of the deployment package"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI for container-based Lambda"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "tracing_mode" {
  description = "X-Ray tracing mode (Active or PassThrough)"
  type        = string
  default     = null
}

variable "dead_letter_target_arn" {
  description = "ARN of the dead letter queue (SQS or SNS)"
  type        = string
  default     = null
}

variable "file_system_config" {
  description = "EFS file system configuration"
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions"
  type        = number
  default     = -1
}

variable "architectures" {
  description = "Lambda function architecture (x86_64 or arm64)"
  type        = list(string)
  default     = ["x86_64"]
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage size in MB"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting logs"
  type        = string
  default     = null
}

variable "policy_json" {
  description = "Additional IAM policy JSON for the Lambda role"
  type        = string
  default     = null
}

variable "create_alias" {
  description = "Create a Lambda alias"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name of the Lambda alias"
  type        = string
  default     = "live"
}

variable "alias_description" {
  description = "Description of the Lambda alias"
  type        = string
  default     = ""
}

variable "alias_function_version" {
  description = "Function version for the alias"
  type        = string
  default     = "$LATEST"
}

variable "allowed_triggers" {
  description = "Map of allowed triggers for Lambda permission"
  type        = map(any)
  default     = {}
}

variable "create_function_url" {
  description = "Create a Lambda function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Authorization type for function URL"
  type        = string
  default     = "NONE"
}

variable "function_url_cors" {
  description = "CORS configuration for function URL"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
