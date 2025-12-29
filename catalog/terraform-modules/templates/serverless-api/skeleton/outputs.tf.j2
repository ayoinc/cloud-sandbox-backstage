# API Outputs
{%- if values.cloudProvider == "aws" %}
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.arn
}

{%- if values.authType == "jwt" %}
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.client_ids["web"]
}
{%- endif %}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
output "function_app_url" {
  description = "Function App URL"
  value       = module.function_app.default_hostname
}

output "function_app_name" {
  description = "Function App name"
  value       = module.function_app.name
}

{%- if values.apiType == "rest" or values.apiType == "graphql" %}
output "api_management_gateway_url" {
  description = "API Management gateway URL"
  value       = module.api_management.gateway_url
}
{%- endif %}

{%- if values.enableTracing %}
output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.app_insights.connection_string
  sensitive   = true
}
{%- endif %}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
output "function_url" {
  description = "Cloud Function URL"
  value       = module.cloud_function.https_trigger_url
}

output "function_name" {
  description = "Cloud Function name"
  value       = module.cloud_function.name
}

{%- if values.apiType == "rest" or values.apiType == "http" %}
output "api_gateway_url" {
  description = "API Gateway URL"
  value       = module.api_gateway.gateway_url
}
{%- endif %}
{%- endif %}

# Database Outputs
{%- if values.enableDatabase %}
{%- if values.cloudProvider == "aws" %}
{%- if values.databaseType == "dynamodb" %}
output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.dynamodb.table_arn
}
{%- elif values.databaseType == "aurora-serverless" %}
output "aurora_endpoint" {
  description = "Aurora Serverless endpoint"
  value       = module.aurora_serverless.endpoint
}
{%- endif %}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
{%- if values.databaseType == "cosmosdb" %}
output "cosmosdb_endpoint" {
  description = "Cosmos DB endpoint"
  value       = module.cosmosdb.endpoint
}

output "cosmosdb_primary_key" {
  description = "Cosmos DB primary key"
  value       = module.cosmosdb.primary_key
  sensitive   = true
}
{%- elif values.databaseType == "sql-serverless" %}
output "sql_server_fqdn" {
  description = "SQL Server FQDN"
  value       = module.sql_serverless.fqdn
}
{%- endif %}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
{%- if values.databaseType == "firestore" %}
output "firestore_database_name" {
  description = "Firestore database name"
  value       = google_firestore_database.main.name
}
{%- elif values.databaseType == "spanner" %}
output "spanner_instance_name" {
  description = "Spanner instance name"
  value       = module.spanner.instance_name
}
{%- endif %}
{%- endif %}
{%- endif %}
