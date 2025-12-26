################################################################################
# AWS Lambda Function Module
# Creates a Lambda function with IAM role, CloudWatch logging, and optional VPC
################################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

################################################################################
# Local Variables
################################################################################

locals {
  function_name = var.function_name

  tags = merge(
    var.tags,
    {
      Module = "lambda"
    }
  )
}

################################################################################
# IAM Role for Lambda
################################################################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  count      = var.tracing_mode != null ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "lambda_additional" {
  count  = var.policy_json != null ? 1 : 0
  name   = "${local.function_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = var.policy_json
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.tags
}

################################################################################
# Lambda Function
################################################################################

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  description   = var.description
  role          = aws_iam_role.lambda.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Source code
  filename          = var.filename
  source_code_hash  = var.source_code_hash
  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = var.s3_object_version
  image_uri         = var.image_uri
  package_type      = var.package_type

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Tracing
  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [1] : []
    content {
      mode = var.tracing_mode
    }
  }

  # Dead letter queue
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  # File system
  dynamic "file_system_config" {
    for_each = var.file_system_config != null ? [var.file_system_config] : []
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  # Layers
  layers = var.layers

  # Reserved concurrency
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Architecture
  architectures = var.architectures

  # Ephemeral storage
  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  tags = local.tags

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic,
  ]
}

################################################################################
# Lambda Alias
################################################################################

resource "aws_lambda_alias" "this" {
  count            = var.create_alias ? 1 : 0
  name             = var.alias_name
  description      = var.alias_description
  function_name    = aws_lambda_function.this.function_name
  function_version = var.alias_function_version
}

################################################################################
# Lambda Permission (for triggers)
################################################################################

resource "aws_lambda_permission" "triggers" {
  for_each = var.allowed_triggers

  statement_id   = each.key
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.this.function_name
  principal      = each.value.principal
  source_arn     = lookup(each.value, "source_arn", null)
  source_account = lookup(each.value, "source_account", null)
}

################################################################################
# Lambda Function URL
################################################################################

resource "aws_lambda_function_url" "this" {
  count              = var.create_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type

  dynamic "cors" {
    for_each = var.function_url_cors != null ? [var.function_url_cors] : []
    content {
      allow_credentials = lookup(cors.value, "allow_credentials", false)
      allow_headers     = lookup(cors.value, "allow_headers", ["*"])
      allow_methods     = lookup(cors.value, "allow_methods", ["*"])
      allow_origins     = lookup(cors.value, "allow_origins", ["*"])
      expose_headers    = lookup(cors.value, "expose_headers", [])
      max_age           = lookup(cors.value, "max_age", 0)
    }
  }
}
