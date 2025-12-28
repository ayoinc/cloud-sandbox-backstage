# -----------------------------------------------------------------------------
# AWS Serverless Module - Main Resources
# -----------------------------------------------------------------------------

# Lambda Function IAM Role
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.vpc_id != null ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.lambda.name
}

# Lambda Secrets Access Policy
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "secrets-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_arn != null ? var.kms_key_arn : "*"
      }
    ]
  })
}

# Lambda Security Group
resource "aws_security_group" "lambda" {
  count = var.vpc_id != null ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda Function
resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-${var.environment}-function"
  role          = aws_iam_role.lambda.arn
  handler       = var.handler
  runtime       = var.runtime

  filename         = var.deployment_package != null ? var.deployment_package : null
  source_code_hash = var.deployment_package != null ? filebase64sha256(var.deployment_package) : null

  # Use placeholder if no package provided
  image_uri = var.image_uri

  memory_size = var.memory_size
  timeout     = var.timeout

  reserved_concurrent_executions = var.reserved_concurrency

  environment {
    variables = merge(var.environment_variables, {
      ENVIRONMENT = var.environment
      PROJECT     = var.project_name
    })
  }

  dynamic "vpc_config" {
    for_each = var.vpc_id != null ? [1] : []
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
  ]
}

# Lambda CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-function"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

# Lambda Alias for deployment
resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.main.function_name
  function_version = aws_lambda_function.main.version
}

# Lambda Provisioned Concurrency (optional)
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

  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = var.cors_allowed_origins
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
    expose_headers    = ["Content-Type"]
    max_age           = 300
    allow_credentials = true
  }

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

resource "aws_cloudwatch_log_group" "api_gateway" {
  count = var.enable_api_gateway ? 1 : 0

  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  count = var.enable_api_gateway ? 1 : 0

  api_id           = aws_apigatewayv2_api.main[0].id
  integration_type = "AWS_PROXY"

  integration_uri    = aws_lambda_alias.live.invoke_arn
  integration_method = "POST"
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

  name                = "${var.project_name}-${var.environment}-schedule"
  description         = "Scheduled trigger for Lambda function"
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
# SQS Queue (Optional)
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "main" {
  count = var.enable_sqs ? 1 : 0

  name                       = "${var.project_name}-${var.environment}-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = var.timeout * 6

  kms_master_key_id = var.kms_key_arn

  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = 3
  }) : null

  tags = var.tags
}

resource "aws_sqs_queue" "dlq" {
  count = var.enable_sqs && var.enable_dlq ? 1 : 0

  name                      = "${var.project_name}-${var.environment}-dlq"
  message_retention_seconds = 1209600 # 14 days
  kms_master_key_id         = var.kms_key_arn

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "sqs" {
  count = var.enable_sqs ? 1 : 0

  event_source_arn = aws_sqs_queue.main[0].arn
  function_name    = aws_lambda_alias.live.arn
  batch_size       = var.sqs_batch_size
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

# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
