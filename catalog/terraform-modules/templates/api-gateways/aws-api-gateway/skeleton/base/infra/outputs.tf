output "api_url" {
  description = "Base URL of the deployed stage."
  value       = aws_api_gateway_stage.this.invoke_url
}

output "api_id" {
  description = "ID of the REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "stage_name" {
  description = "Name of the deployed stage."
  value       = aws_api_gateway_stage.this.stage_name
}

output "lambda_function_name" {
  description = "Name of the function behind the API."
  value       = module.lambda.function_name
}

output "items_table_name" {
  description = "DynamoDB table of the /items endpoints, when they are enabled."
  value       = one(aws_dynamodb_table.items[*].name)
}

output "api_key_id" {
  description = "ID of the first API key, when auth_type is apikey. Read its value with: aws apigateway get-api-key --include-value --api-key <id>."
  value       = one(aws_api_gateway_api_key.default[*].id)
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool, when auth_type is cognito."
  value       = one(aws_cognito_user_pool.this[*].id)
}

output "cognito_user_pool_client_id" {
  description = "ID of the app client used to sign in, when auth_type is cognito."
  value       = one(aws_cognito_user_pool_client.this[*].id)
}

output "web_acl_arn" {
  description = "ARN of the WAF web ACL, when WAF is enabled."
  value       = one(module.waf[*].web_acl_arn)
}

output "dashboard_name" {
  description = "CloudWatch dashboard of the API, when monitoring is enabled."
  value       = var.enable_monitoring ? var.api_name : null
}
