# =============================================================================
# AWS Lambda Module
# =============================================================================
# Reusable module for creating Lambda functions with IAM role, logging,
# and optional VPC configuration.
# =============================================================================

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  description      = var.description
  role             = aws_iam_role.lambda.arn
  handler          = var.handler
  runtime          = var.runtime
  memory_size      = var.memory_size
  timeout          = var.timeout
  filename         = var.filename
  source_code_hash = var.source_code_hash

  # Optional: Use S3 instead of local file
  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = var.s3_object_version

  # Reserved concurrency (0 = disabled, null = unreserved)
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Publish version on each update
  publish = var.publish_version

  # Architecture
  architectures = var.architectures

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = merge(
        {
          ENVIRONMENT = var.environment
        },
        var.environment_variables
      )
    }
  }

  # VPC configuration (optional)
  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null && length(var.vpc_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  # Dead letter queue (optional)
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  # Tracing configuration
  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [1] : []
    content {
      mode = var.tracing_mode
    }
  }

  # Ephemeral storage
  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  # Layers
  layers = var.layers

  tags = merge(
    {
      Name        = local.function_name
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy_attachment.lambda_xray,
    aws_cloudwatch_log_group.lambda,
  ]

  lifecycle {
    ignore_changes = [
      # Ignore changes to qualified_arn as it changes with each publish
      qualified_arn,
    ]
  }
}

# -----------------------------------------------------------------------------
# IAM Role for Lambda
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "${local.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name        = "${local.function_name}-role"
      Environment = var.environment
    },
    var.tags
  )
}

# Basic execution policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC execution policy (if VPC enabled)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = var.vpc_subnet_ids != null && length(var.vpc_subnet_ids) > 0 ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# X-Ray tracing policy (if tracing enabled)
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  count      = var.tracing_mode != null ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Custom IAM policy (optional)
resource "aws_iam_role_policy" "custom" {
  count  = var.custom_iam_policy != null ? 1 : 0
  name   = "${local.function_name}-custom-policy"
  role   = aws_iam_role.lambda.id
  policy = var.custom_iam_policy
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    {
      Name        = "${local.function_name}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Lambda Alias (optional)
# -----------------------------------------------------------------------------
resource "aws_lambda_alias" "live" {
  count            = var.create_alias ? 1 : 0
  name             = "live"
  description      = "Live production alias"
  function_name    = aws_lambda_function.this.function_name
  function_version = var.publish_version ? aws_lambda_function.this.version : "$LATEST"

  # Traffic shifting for blue/green deployments
  dynamic "routing_config" {
    for_each = var.alias_routing_config != null ? [var.alias_routing_config] : []
    content {
      additional_version_weights = routing_config.value
    }
  }
}

# -----------------------------------------------------------------------------
# Lambda Function URL (optional)
# -----------------------------------------------------------------------------
resource "aws_lambda_function_url" "this" {
  count              = var.create_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type

  dynamic "cors" {
    for_each = var.function_url_cors != null ? [var.function_url_cors] : []
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
# CloudWatch Alarms (optional)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "errors" {
  count               = var.create_error_alarm ? 1 : 0
  alarm_name          = "${local.function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_alarm_threshold
  alarm_description   = "Lambda function error rate exceeded threshold"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  count               = var.create_duration_alarm ? 1 : 0
  alarm_name          = "${local.function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = var.duration_alarm_threshold
  alarm_description   = "Lambda function duration exceeded threshold"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  count               = var.create_throttle_alarm ? 1 : 0
  alarm_name          = "${local.function_name}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.throttle_alarm_threshold
  alarm_description   = "Lambda function throttles exceeded threshold"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------
locals {
  function_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}-${var.environment}" : "${var.name}-${var.environment}"
}
