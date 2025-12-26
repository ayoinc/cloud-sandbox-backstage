# -----------------------------------------------------------------------------
# AWS Serverless Module - Outputs
# -----------------------------------------------------------------------------

# Lambda Outputs
output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.main.arn
}

output "function_invoke_arn" {
  description = "Lambda function invoke ARN"
  value       = aws_lambda_function.main.invoke_arn
}

output "function_version" {
  description = "Lambda function version"
  value       = aws_lambda_function.main.version
}

output "alias_arn" {
  description = "Lambda alias ARN"
  value       = aws_lambda_alias.live.arn
}

output "role_arn" {
  description = "Lambda IAM role ARN"
  value       = aws_iam_role.lambda.arn
}

output "security_group_id" {
  description = "Lambda security group ID"
  value       = var.vpc_id != null ? aws_security_group.lambda[0].id : null
}

output "log_group_name" {
  description = "Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

# API Gateway Outputs
output "api_id" {
  description = "API Gateway ID"
  value       = var.enable_api_gateway ? aws_apigatewayv2_api.main[0].id : null
}

output "api_endpoint" {
  description = "API Gateway endpoint"
  value       = var.enable_api_gateway ? aws_apigatewayv2_api.main[0].api_endpoint : null
}

output "api_url" {
  description = "API Gateway URL (with stage)"
  value       = var.enable_api_gateway ? "${aws_apigatewayv2_api.main[0].api_endpoint}/${var.environment}" : null
}

# SQS Outputs
output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = var.enable_sqs ? aws_sqs_queue.main[0].url : null
}

output "sqs_queue_arn" {
  description = "SQS queue ARN"
  value       = var.enable_sqs ? aws_sqs_queue.main[0].arn : null
}

output "dlq_url" {
  description = "Dead-letter queue URL"
  value       = var.enable_sqs && var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_arn" {
  description = "Dead-letter queue ARN"
  value       = var.enable_sqs && var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}
