# -----------------------------------------------------------------------------
# AWS Lambda Function Module
# -----------------------------------------------------------------------------
# Creates Lambda functions with VPC, layers, and event source mappings
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "index.handler"
}

variable "architectures" {
  description = "Instruction set architectures"
  type        = list(string)
  default     = ["x86_64"]
}

variable "memory_size" {
  description = "Memory size in MB"
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage size in MB"
  type        = number
  default     = 512
}

variable "package_type" {
  description = "Package type (Zip or Image)"
  type        = string
  default     = "Zip"
}

variable "filename" {
  description = "Path to the deployment package"
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
  description = "URI of the container image"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Hash of the deployment package for change detection"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "role_arn" {
  description = "IAM role ARN for the Lambda function"
  type        = string
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions (-1 for unreserved)"
  type        = number
  default     = -1
}

variable "publish" {
  description = "Publish a new version of the function"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for environment variable encryption"
  type        = string
  default     = null
}

variable "dead_letter_config" {
  description = "Dead letter queue configuration"
  type = object({
    target_arn = string
  })
  default = null
}

variable "tracing_config" {
  description = "X-Ray tracing configuration"
  type = object({
    mode = string
  })
  default = {
    mode = "PassThrough"
  }
}

variable "file_system_config" {
  description = "EFS file system configuration"
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null
}

variable "create_function_url" {
  description = "Create a function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Function URL authorization type"
  type        = string
  default     = "AWS_IAM"
}

variable "cors_config" {
  description = "CORS configuration for function URL"
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string), [])
    allow_methods     = optional(list(string), [])
    allow_origins     = optional(list(string), [])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 0)
  })
  default = null
}

variable "permissions" {
  description = "Map of Lambda permissions to create"
  type = map(object({
    statement_id       = optional(string)
    action             = optional(string, "lambda:InvokeFunction")
    principal          = string
    source_arn         = optional(string)
    source_account     = optional(string)
    event_source_token = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = var.role_arn
  handler       = var.package_type == "Zip" ? var.handler : null
  runtime       = var.package_type == "Zip" ? var.runtime : null
  architectures = var.architectures

  package_type      = var.package_type
  filename          = var.filename
  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = var.s3_object_version
  image_uri         = var.image_uri
  source_code_hash  = var.source_code_hash

  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  publish                        = var.publish
  kms_key_arn                    = var.kms_key_arn
  layers                         = var.layers

  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config != null ? [var.tracing_config] : []
    content {
      mode = tracing_config.value.mode
    }
  }

  dynamic "file_system_config" {
    for_each = var.file_system_config != null ? [var.file_system_config] : []
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  tags = merge(var.tags, {
    Name = var.function_name
  })
}

# -----------------------------------------------------------------------------
# Function URL
# -----------------------------------------------------------------------------

resource "aws_lambda_function_url" "this" {
  count = var.create_function_url ? 1 : 0

  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type

  dynamic "cors" {
    for_each = var.cors_config != null ? [var.cors_config] : []
    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age           = cors.value.max_age
    }
  }
}

# -----------------------------------------------------------------------------
# Permissions
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "this" {
  for_each = var.permissions

  function_name      = aws_lambda_function.this.function_name
  statement_id       = each.value.statement_id != null ? each.value.statement_id : each.key
  action             = each.value.action
  principal          = each.value.principal
  source_arn         = each.value.source_arn
  source_account     = each.value.source_account
  event_source_token = each.value.event_source_token
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "Invoke ARN for API Gateway"
  value       = aws_lambda_function.this.invoke_arn
}

output "qualified_arn" {
  description = "Qualified ARN with version"
  value       = aws_lambda_function.this.qualified_arn
}

output "version" {
  description = "Latest published version"
  value       = aws_lambda_function.this.version
}

output "function_url" {
  description = "Function URL endpoint"
  value       = var.create_function_url ? aws_lambda_function_url.this[0].function_url : null
}
