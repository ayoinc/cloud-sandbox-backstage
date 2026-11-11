# -----------------------------------------------------------------------------
# AWS Serverless Module - Main Resources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  # Lowercase, hyphen-separated and short enough for every AWS name limit.
  project     = trimsuffix(substr(replace(lower(var.project_name), "/[^a-z0-9]+/", "-"), 0, 23), "-")
  name_prefix = "${local.project}-${var.environment}"

  # Secrets of the project live under this path.
  path_prefix = "${local.project}/${var.environment}"

  function_name         = "${local.name_prefix}-function"
  managed_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  is_image         = var.package_type == "Image"
  use_builtin_code = !local.is_image && var.deployment_package == null

  package_file = local.is_image ? null : (local.use_builtin_code ? data.archive_file.builtin[0].output_path : var.deployment_package)
  package_hash = local.is_image ? null : (local.use_builtin_code ? data.archive_file.builtin[0].output_base64sha256 : filebase64sha256(var.deployment_package))

  # Browsers reject credentialed CORS responses for a wildcard origin.
  cors_allow_credentials = !contains(var.cors_allowed_origins, "*")
}

# Packages the built-in handler when no deployment package is supplied.
data "archive_file" "builtin" {
  count = local.use_builtin_code ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.module}/.build/${local.function_name}.zip"
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "${local.managed_policy_prefix}/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.enable_vpc ? 1 : 0

  policy_arn = "${local.managed_policy_prefix}/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  count = var.enable_xray ? 1 : 0

  policy_arn = "${local.managed_policy_prefix}/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.lambda.name
}

# The function may read the project's secrets and, when a customer managed
# key is used, decrypt with that key only.
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "secrets-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.path_prefix}/*"
      }],
      var.kms_key_arn != null ? [{
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arn
      }] : []
    )
  })
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

resource "aws_security_group" "lambda" {
  count = var.enable_vpc ? 1 : 0

  name_prefix = "${local.name_prefix}-lambda-"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-lambda-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "selected" {
  count = var.enable_vpc ? 1 : 0

  id = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "lambda_vpc" {
  count = var.enable_vpc ? 1 : 0

  security_group_id = aws_security_group.lambda[0].id
  description       = "Any traffic to destinations inside the VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = data.aws_vpc.selected[0].cidr_block

  tags = var.tags
}

# The function calls AWS APIs (Secrets Manager, SQS, X-Ray) and external
# HTTPS services; these endpoints have no fixed address range.
# trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "lambda_https" {
  count = var.enable_vpc ? 1 : 0

  security_group_id = aws_security_group.lambda[0].id
  description       = "HTTPS to AWS APIs and external services"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_lambda_function" "main" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  package_type  = var.package_type

  # Zip packages
  filename         = local.package_file
  source_code_hash = local.package_hash
  handler          = local.is_image ? null : var.handler
  runtime          = local.is_image ? null : var.runtime

  # Container images
  image_uri = local.is_image ? var.image_uri : null

  memory_size = var.memory_size
  timeout     = var.timeout

  # Every change publishes a version for the live alias to point at.
  publish = true

  reserved_concurrent_executions = var.reserved_concurrency

  kms_key_arn = var.kms_key_arn

  environment {
    variables = merge(var.environment_variables, {
      ENVIRONMENT = var.environment
      PROJECT     = local.project
    })
  }

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]
}

# Stable name that triggers invoke; it follows the latest published version.
resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.main.function_name
  function_version = aws_lambda_function.main.version
}

resource "aws_lambda_provisioned_concurrency_config" "main" {
  count = var.provisioned_concurrency > 0 ? 1 : 0

  function_name                     = aws_lambda_function.main.function_name
  provisioned_concurrent_executions = var.provisioned_concurrency
  qualifier                         = aws_lambda_alias.live.name
}

# -----------------------------------------------------------------------------
# API Gateway (HTTP API)
# -----------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "main" {
  count = var.enable_api_gateway ? 1 : 0

  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = var.cors_allowed_origins
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
    expose_headers    = ["Content-Type"]
    max_age           = 300
    allow_credentials = local.cors_allow_credentials
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  count = var.enable_api_gateway ? 1 : 0

  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "main" {
  count = var.enable_api_gateway ? 1 : 0

  api_id      = aws_apigatewayv2_api.main[0].id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      protocol           = "$context.protocol"
      responseLength     = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
    })
  }

  default_route_settings {
    throttling_burst_limit = var.api_throttle_burst
    throttling_rate_limit  = var.api_throttle_rate
  }

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  count = var.enable_api_gateway ? 1 : 0

  api_id                 = aws_apigatewayv2_api.main[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_alias.live.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  count = var.enable_api_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[0].id}"
}

resource "aws_lambda_permission" "api_gateway" {
  count = var.enable_api_gateway ? 1 : 0

  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
  qualifier     = aws_lambda_alias.live.name
}

# -----------------------------------------------------------------------------
# EventBridge Rule (Scheduled Events)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "schedule" {
  count = var.schedule_expression != null ? 1 : 0

  name                = "${local.name_prefix}-schedule"
  description         = "Scheduled trigger for ${local.function_name}"
  schedule_expression = var.schedule_expression

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = var.schedule_expression != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.schedule[0].name
  target_id = "lambda"
  arn       = aws_lambda_alias.live.arn
}

resource "aws_lambda_permission" "eventbridge" {
  count = var.schedule_expression != null ? 1 : 0

  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[0].arn
  qualifier     = aws_lambda_alias.live.name
}

# -----------------------------------------------------------------------------
# SQS Queue
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  count = var.enable_sqs && var.enable_dlq ? 1 : 0

  name                      = "${local.name_prefix}-dlq"
  message_retention_seconds = 1209600 # 14 days

  # SQS managed encryption unless a customer managed key is supplied.
  kms_master_key_id       = var.kms_key_arn
  sqs_managed_sse_enabled = var.kms_key_arn == null ? true : null

  tags = var.tags
}

resource "aws_sqs_queue" "main" {
  count = var.enable_sqs ? 1 : 0

  name                      = "${local.name_prefix}-queue"
  message_retention_seconds = 345600 # 4 days
  receive_wait_time_seconds = 10

  # Six times the function timeout, as recommended for Lambda triggers.
  visibility_timeout_seconds = var.timeout * 6

  kms_master_key_id       = var.kms_key_arn
  sqs_managed_sse_enabled = var.kms_key_arn == null ? true : null

  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = 3
  }) : null

  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_sqs" {
  count = var.enable_sqs ? 1 : 0

  name = "sqs-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main[0].arn
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "sqs" {
  count = var.enable_sqs ? 1 : 0

  event_source_arn        = aws_sqs_queue.main[0].arn
  function_name           = aws_lambda_alias.live.arn
  batch_size              = var.sqs_batch_size
  function_response_types = ["ReportBatchItemFailures"]

  depends_on = [aws_iam_role_policy.lambda_sqs]
}
