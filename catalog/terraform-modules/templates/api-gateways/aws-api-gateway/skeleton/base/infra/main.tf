data "aws_partition" "current" {}

locals {
  auth_type  = var.enable_auth ? var.auth_type : "none"
  stage_name = "v${split(".", var.api_version)[0]}"

  tags = merge(
    {
      Service    = var.api_name
      ApiVersion = var.api_version
      ManagedBy  = "terraform"
    },
    var.tags
  )

  crud_routes = [
    { method = "GET", path = "/items", description = "List items" },
    { method = "POST", path = "/items", description = "Create an item" },
    { method = "GET", path = "/items/{id}", description = "Get an item" },
    { method = "PUT", path = "/items/{id}", description = "Replace an item" },
    { method = "DELETE", path = "/items/{id}", description = "Delete an item" },
  ]

  # Every route of the API. The health check is always open; the others
  # require the configured authentication.
  routes = concat(
    [{ method = "GET", path = "/health", description = "Health check", public = true }],
    [for r in local.crud_routes : merge(r, { public = false }) if var.enable_crud],
    [for e in var.endpoints : { method = upper(e.method), path = e.path, description = e.description, public = false }],
  )

  all_security_schemes = {
    apikey = {
      type = "apiKey"
      name = "x-api-key"
      in   = "header"
    }
    jwt = {
      type                           = "apiKey"
      name                           = "Authorization"
      in                             = "header"
      "x-amazon-apigateway-authtype" = "custom"
      "x-amazon-apigateway-authorizer" = {
        type                         = "token"
        authorizerUri                = one(module.authorizer[*].invoke_arn)
        authorizerResultTtlInSeconds = 300
        identityValidationExpression = "^Bearer [A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$"
      }
    }
    cognito = {
      type                           = "apiKey"
      name                           = "Authorization"
      in                             = "header"
      "x-amazon-apigateway-authtype" = "cognito_user_pools"
      "x-amazon-apigateway-authorizer" = {
        type         = "cognito_user_pools"
        providerARNs = aws_cognito_user_pool.this[*].arn
      }
    }
  }

  # The API is defined as an OpenAPI document so that paths of any depth can
  # be added through var.endpoints without declaring a resource per segment.
  openapi = {
    openapi = "3.0.1"
    info = {
      title       = var.api_name
      description = var.description
      version     = var.api_version
    }
    paths = {
      for path in distinct(local.routes[*].path) : path => {
        for r in local.routes : lower(r.method) => {
          summary   = r.description
          security  = [for scheme in [local.auth_type] : { (scheme) = [] } if scheme != "none" && !r.public]
          responses = { default = { description = "Response of the Lambda function" } }
          "x-amazon-apigateway-integration" = {
            type                = "aws_proxy"
            httpMethod          = "POST"
            uri                 = module.lambda.invoke_arn
            passthroughBehavior = "when_no_match"
          }
        } if r.path == path
      }
    }
    components = {
      securitySchemes = { for name, scheme in local.all_security_schemes : name => scheme if name == local.auth_type }
    }
  }
}

resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.description
  body        = jsonencode(local.openapi)

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    precondition {
      condition     = local.auth_type != "jwt" || (var.jwt_issuer != "" && var.jwt_audience != "")
      error_message = "auth_type is jwt: set jwt_issuer and jwt_audience to the issuer and audience of the tokens the API accepts."
    }
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    definition = sha1(jsonencode(local.openapi))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  deployment_id        = aws_api_gateway_deployment.this.id
  stage_name           = local.stage_name
  description          = "${var.api_name} ${var.api_version}"
  xray_tracing_enabled = var.enable_xray

  dynamic "access_log_settings" {
    for_each = module.monitoring[*].log_group_arn

    content {
      destination_arn = access_log_settings.value
      format = jsonencode({
        requestId      = "$context.requestId"
        requestTime    = "$context.requestTime"
        sourceIp       = "$context.identity.sourceIp"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        responseLength = "$context.responseLength"
        latency        = "$context.responseLatency"
        integration    = "$context.integrationErrorMessage"
      })
    }
  }

  depends_on = [aws_api_gateway_account.this]
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = var.enable_monitoring
    logging_level   = var.enable_monitoring ? "ERROR" : "OFF"

    # -1 switches throttling off for the stage.
    throttling_rate_limit  = var.enable_rate_limiting ? var.requests_per_second : -1
    throttling_burst_limit = var.enable_rate_limiting ? var.requests_per_second * 2 : -1
  }
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*/*"
}
