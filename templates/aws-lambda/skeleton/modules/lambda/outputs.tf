# =============================================================================
# AWS Lambda Module - Outputs
# =============================================================================
# Output values from the Lambda module.
# =============================================================================

# -----------------------------------------------------------------------------
# Function Outputs
# -----------------------------------------------------------------------------
output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function (includes version)"
  value       = aws_lambda_function.this.qualified_arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "last_modified" {
  description = "Date the function was last modified"
  value       = aws_lambda_function.this.last_modified
}

output "source_code_size" {
  description = "Size in bytes of the function .zip file"
  value       = aws_lambda_function.this.source_code_size
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------
output "role_name" {
  description = "Name of the Lambda IAM role"
  value       = aws_iam_role.lambda.name
}

output "role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

output "role_id" {
  description = "ID of the Lambda IAM role"
  value       = aws_iam_role.lambda.id
}

# -----------------------------------------------------------------------------
# Logging Outputs
# -----------------------------------------------------------------------------
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.arn
}

# -----------------------------------------------------------------------------
# Alias Outputs
# -----------------------------------------------------------------------------
output "alias_name" {
  description = "Name of the Lambda alias"
  value       = var.create_alias ? aws_lambda_alias.live[0].name : null
}

output "alias_arn" {
  description = "ARN of the Lambda alias"
  value       = var.create_alias ? aws_lambda_alias.live[0].arn : null
}

output "alias_invoke_arn" {
  description = "Invoke ARN of the Lambda alias"
  value       = var.create_alias ? aws_lambda_alias.live[0].invoke_arn : null
}

# -----------------------------------------------------------------------------
# Function URL Outputs
# -----------------------------------------------------------------------------
output "function_url" {
  description = "URL of the Lambda function (if enabled)"
  value       = var.create_function_url ? aws_lambda_function_url.this[0].function_url : null
}

output "function_url_id" {
  description = "ID of the Lambda function URL (if enabled)"
  value       = var.create_function_url ? aws_lambda_function_url.this[0].url_id : null
}

# -----------------------------------------------------------------------------
# Configuration Outputs
# -----------------------------------------------------------------------------
output "runtime" {
  description = "Lambda runtime"
  value       = aws_lambda_function.this.runtime
}

output "handler" {
  description = "Lambda handler"
  value       = aws_lambda_function.this.handler
}

output "memory_size" {
  description = "Lambda memory size in MB"
  value       = aws_lambda_function.this.memory_size
}

output "timeout" {
  description = "Lambda timeout in seconds"
  value       = aws_lambda_function.this.timeout
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# -----------------------------------------------------------------------------
# Function Information Summary
# -----------------------------------------------------------------------------
output "function_info" {
  description = "Summary of Lambda function configuration"
  value = {
    name        = aws_lambda_function.this.function_name
    arn         = aws_lambda_function.this.arn
    version     = aws_lambda_function.this.version
    runtime     = aws_lambda_function.this.runtime
    handler     = aws_lambda_function.this.handler
    memory_size = aws_lambda_function.this.memory_size
    timeout     = aws_lambda_function.this.timeout
    role_arn    = aws_iam_role.lambda.arn
    log_group   = aws_cloudwatch_log_group.lambda.name
    alias_arn   = var.create_alias ? aws_lambda_alias.live[0].arn : null
    url         = var.create_function_url ? aws_lambda_function_url.this[0].function_url : null
  }
}
