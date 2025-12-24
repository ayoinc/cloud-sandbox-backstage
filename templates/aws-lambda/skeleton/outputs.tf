# =============================================================================
# AWS Lambda - Root Outputs
# =============================================================================
# Output values from the Lambda module exposed at the root level.
# =============================================================================

# -----------------------------------------------------------------------------
# Function Outputs
# -----------------------------------------------------------------------------
output "function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function (includes version)"
  value       = module.lambda.function_qualified_arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.lambda.invoke_arn
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = module.lambda.function_version
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------
output "role_name" {
  description = "Name of the Lambda IAM role"
  value       = module.lambda.role_name
}

output "role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = module.lambda.role_arn
}

# -----------------------------------------------------------------------------
# Logging Outputs
# -----------------------------------------------------------------------------
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.lambda.log_group_name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = module.lambda.log_group_arn
}

# -----------------------------------------------------------------------------
# Alias Outputs
# -----------------------------------------------------------------------------
output "alias_name" {
  description = "Name of the Lambda alias"
  value       = module.lambda.alias_name
}

output "alias_arn" {
  description = "ARN of the Lambda alias"
  value       = module.lambda.alias_arn
}

output "alias_invoke_arn" {
  description = "Invoke ARN of the Lambda alias"
  value       = module.lambda.alias_invoke_arn
}

# -----------------------------------------------------------------------------
# Function URL Outputs
# -----------------------------------------------------------------------------
output "function_url" {
  description = "URL of the Lambda function (if enabled)"
  value       = module.lambda.function_url
}

# -----------------------------------------------------------------------------
# Configuration Outputs
# -----------------------------------------------------------------------------
output "runtime" {
  description = "Lambda runtime"
  value       = module.lambda.runtime
}

output "handler" {
  description = "Lambda handler"
  value       = module.lambda.handler
}

output "memory_size" {
  description = "Lambda memory size in MB"
  value       = module.lambda.memory_size
}

output "timeout" {
  description = "Lambda timeout in seconds"
  value       = module.lambda.timeout
}

output "environment" {
  description = "Environment name"
  value       = module.lambda.environment
}

# -----------------------------------------------------------------------------
# Function Information Summary
# -----------------------------------------------------------------------------
output "function_info" {
  description = "Summary of Lambda function configuration"
  value       = module.lambda.function_info
}
