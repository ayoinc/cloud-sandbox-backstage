locals {
  lambda_package = "${path.module}/${var.lambda_package}"
  managed_policy = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
}

module "lambda_role" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/core/iam-role?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  name             = "${var.api_name}-lambda"
  description      = "Execution role of the ${var.api_name} function"
  trusted_services = ["lambda.amazonaws.com"]

  managed_policy_arns = concat(
    ["${local.managed_policy}/service-role/AWSLambdaBasicExecutionRole"],
    var.enable_xray ? ["${local.managed_policy}/AWSXRayDaemonWriteAccess"] : [],
  )

  inline_policies = var.enable_crud ? {
    items-table = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
        ]
        Resource = one(aws_dynamodb_table.items[*].arn)
      }]
    })
  } : {}

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.api_name}"
  retention_in_days = var.log_retention_days

  lifecycle {
    precondition {
      condition     = fileexists(local.lambda_package)
      error_message = "The deployment package ${var.lambda_package} does not exist. Build it first: see docs/development.md."
    }
  }
}

module "lambda" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/compute/lambda?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  function_name = var.api_name
  description   = var.description
  runtime       = var.lambda_runtime
  handler       = var.lambda_handler
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  role_arn      = module.lambda_role.role_arn

  filename         = local.lambda_package
  source_code_hash = fileexists(local.lambda_package) ? filebase64sha256(local.lambda_package) : null

  environment_variables = merge(
    {
      API_NAME    = var.api_name
      API_VERSION = var.api_version
    },
    var.enable_crud ? { ITEMS_TABLE = one(aws_dynamodb_table.items[*].name) } : {},
  )

  tracing_config = {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  tags = local.tags

  depends_on = [aws_cloudwatch_log_group.lambda]
}

# Storage of the generated /items endpoints.
resource "aws_dynamodb_table" "items" {
  count = var.enable_crud ? 1 : 0

  name         = "${var.api_name}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}
