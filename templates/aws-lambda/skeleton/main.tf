# =============================================================================
# AWS Lambda Infrastructure
# =============================================================================
# Root module that calls the Lambda child module.
# Environment-specific values are provided via -var-file.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Package the Lambda Code
# -----------------------------------------------------------------------------
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

# -----------------------------------------------------------------------------
# Lambda Module
# -----------------------------------------------------------------------------
module "lambda" {
  source = "./modules/lambda"

  # Project Configuration
  name        = var.name
  environment = var.environment
  description = var.description

  # Runtime Configuration
  runtime = var.runtime
  handler = var.handler

  # Package Configuration
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  # Resource Configuration
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  publish_version                = var.publish_version
  architectures                  = var.architectures
  ephemeral_storage_size         = var.ephemeral_storage_size
  layers                         = var.layers

  # Environment Variables
  environment_variables = var.environment_variables

  # VPC Configuration
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids

  # Dead Letter Queue
  dead_letter_target_arn = var.dead_letter_target_arn

  # Tracing
  tracing_mode = var.tracing_mode

  # Logging
  log_retention_days = var.log_retention_days
  log_kms_key_id     = var.log_kms_key_id

  # IAM
  custom_iam_policy = var.custom_iam_policy

  # Alias
  create_alias         = var.create_alias
  alias_routing_config = var.alias_routing_config

  # Function URL
  create_function_url    = var.create_function_url
  function_url_auth_type = var.function_url_auth_type
  function_url_cors      = var.function_url_cors

  # Alarms
  create_error_alarm       = var.create_error_alarm
  error_alarm_threshold    = var.error_alarm_threshold
  create_duration_alarm    = var.create_duration_alarm
  duration_alarm_threshold = var.duration_alarm_threshold
  create_throttle_alarm    = var.create_throttle_alarm
  throttle_alarm_threshold = var.throttle_alarm_threshold
  alarm_actions            = var.alarm_actions

  # Tags
  tags = var.tags
}
