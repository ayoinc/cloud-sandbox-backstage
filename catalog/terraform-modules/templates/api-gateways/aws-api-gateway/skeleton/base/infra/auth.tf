# -----------------------------------------------------------------------------
# auth_type = "apikey": an API key and a usage plan
# -----------------------------------------------------------------------------

resource "aws_api_gateway_api_key" "default" {
  count = local.auth_type == "apikey" ? 1 : 0

  name        = "${var.api_name}-default"
  description = "First client key of ${var.api_name}"
}

resource "aws_api_gateway_usage_plan" "default" {
  count = local.auth_type == "apikey" ? 1 : 0

  name        = var.api_name
  description = "Clients of ${var.api_name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }

  # Applies to each API key separately.
  dynamic "throttle_settings" {
    for_each = var.enable_rate_limiting ? [var.requests_per_second] : []

    content {
      rate_limit  = throttle_settings.value
      burst_limit = throttle_settings.value * 2
    }
  }
}

resource "aws_api_gateway_usage_plan_key" "default" {
  count = local.auth_type == "apikey" ? 1 : 0

  key_id        = aws_api_gateway_api_key.default[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.default[0].id
}

# -----------------------------------------------------------------------------
# auth_type = "cognito": a user pool whose ID tokens the API accepts
# -----------------------------------------------------------------------------

resource "aws_cognito_user_pool" "this" {
  count = local.auth_type == "cognito" ? 1 : 0

  name                     = var.api_name
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "this" {
  count = local.auth_type == "cognito" ? 1 : 0

  name                          = "${var.api_name}-client"
  user_pool_id                  = aws_cognito_user_pool.this[0].id
  generate_secret               = false
  explicit_auth_flows           = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors = "ENABLED"
}

# -----------------------------------------------------------------------------
# auth_type = "jwt": a Lambda authorizer that verifies tokens of jwt_issuer
# -----------------------------------------------------------------------------

data "archive_file" "authorizer" {
  count = local.auth_type == "jwt" ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/../authorizer/index.mjs"
  output_path = "${path.module}/../build/authorizer.zip"
}

module "authorizer_role" {
  count  = local.auth_type == "jwt" ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/core/iam-role?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  name                = "${var.api_name}-authorizer"
  description         = "Execution role of the ${var.api_name} token authorizer"
  trusted_services    = ["lambda.amazonaws.com"]
  managed_policy_arns = ["${local.managed_policy}/service-role/AWSLambdaBasicExecutionRole"]

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "authorizer" {
  count = local.auth_type == "jwt" ? 1 : 0

  name              = "/aws/lambda/${var.api_name}-authorizer"
  retention_in_days = var.log_retention_days
}

module "authorizer" {
  count  = local.auth_type == "jwt" ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/compute/lambda?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  function_name = "${var.api_name}-authorizer"
  description   = "Verifies the bearer tokens sent to ${var.api_name}"
  runtime       = "nodejs24.x"
  handler       = "index.handler"
  memory_size   = 256
  timeout       = 10
  role_arn      = module.authorizer_role[0].role_arn

  filename         = data.archive_file.authorizer[0].output_path
  source_code_hash = data.archive_file.authorizer[0].output_base64sha256

  environment_variables = {
    JWT_ISSUER   = var.jwt_issuer
    JWT_AUDIENCE = var.jwt_audience
    JWKS_URI     = var.jwt_jwks_uri != "" ? var.jwt_jwks_uri : "${trimsuffix(var.jwt_issuer, "/")}/.well-known/jwks.json"
  }

  tracing_config = {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  tags = local.tags

  depends_on = [aws_cloudwatch_log_group.authorizer]
}

resource "aws_lambda_permission" "authorizer" {
  count = local.auth_type == "jwt" ? 1 : 0

  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.authorizer[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/authorizers/*"
}
