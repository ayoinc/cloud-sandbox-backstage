variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "${{ values.projectName }}"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "${{ values.environment }}"
}

variable "region" {
  description = "Cloud region"
  type        = string
  {%- if values.cloudProvider == "aws" %}
  default     = "${{ values.awsRegion }}"
  {%- elif values.cloudProvider == "azure" %}
  default     = "${{ values.azureRegion }}"
  {%- else %}
  default     = "${{ values.gcpRegion }}"
  {%- endif %}
}

{%- if values.cloudProvider == "azure" %}
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "${{ values.azureSubscriptionId }}"
}

variable "api_publisher_name" {
  description = "API Management publisher name"
  type        = string
  default     = "Platform Team"
}

variable "api_publisher_email" {
  description = "API Management publisher email"
  type        = string
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = "${{ values.gcpProjectId }}"
}

variable "source_bucket" {
  description = "GCS bucket containing function source"
  type        = string
}

variable "source_object" {
  description = "GCS object path for function source"
  type        = string
}

variable "entry_point" {
  description = "Function entry point"
  type        = string
  default     = "handler"
}
{%- endif %}

{%- if values.cloudProvider == "aws" %}
variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "index.handler"
}

variable "deployment_package" {
  description = "Path to deployment package"
  type        = string
  default     = ""
}

variable "source_code_hash" {
  description = "Source code hash for deployment"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID (optional, for VPC-enabled Lambda)"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (optional, for VPC-enabled Lambda)"
  type        = list(string)
  default     = []
}

{%- if values.authType == "jwt" %}
variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
  default     = ""
}
{%- endif %}

{%- if values.enableAlarms %}
variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
  default     = ""
}
{%- endif %}
{%- endif %}

variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

{%- if values.enableCors %}
variable "cors_allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}
{%- endif %}

{%- if values.apiType == "rest" or values.apiType == "graphql" %}
variable "openapi_spec" {
  description = "OpenAPI specification"
  type        = string
  default     = ""
}
{%- endif %}

{%- if values.apiType == "graphql" %}
variable "graphql_schema" {
  description = "GraphQL schema"
  type        = string
  default     = ""
}
{%- endif %}

{%- if values.enableDatabase %}
{%- if values.databaseType == "dynamodb" %}
variable "dynamodb_hash_key" {
  description = "DynamoDB hash key name"
  type        = string
  default     = "pk"
}

variable "dynamodb_range_key" {
  description = "DynamoDB range key name"
  type        = string
  default     = "sk"
}

variable "dynamodb_attributes" {
  description = "DynamoDB attribute definitions"
  type = list(object({
    name = string
    type = string
  }))
  default = [
    { name = "pk", type = "S" },
    { name = "sk", type = "S" }
  ]
}
{%- endif %}

{%- if values.databaseType == "aurora-serverless" or values.databaseType == "sql-serverless" %}
variable "database_username" {
  description = "Database admin username"
  type        = string
  default     = "admin"
}

variable "database_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true
}
{%- endif %}
{%- endif %}
