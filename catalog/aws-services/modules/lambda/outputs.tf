################################################################################
# Lambda Function Outputs
################################################################################

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

output "role_name" {
  description = "Name of the Lambda IAM role"
  value       = aws_iam_role.lambda.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "alias_arn" {
  description = "ARN of the Lambda alias"
  value       = try(aws_lambda_alias.this[0].arn, null)
}

output "function_url" {
  description = "Lambda function URL"
  value       = try(aws_lambda_function_url.this[0].function_url, null)
}
