mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-2"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}

variables {
  project_name = "My_Project"
  environment  = "dev"
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_lambda_function.main.function_name == "my-project-dev-function"
    error_message = "The function name must be derived from the name prefix."
  }

  assert {
    condition     = aws_lambda_function.main.package_type == "Zip" && aws_lambda_function.main.runtime == "python3.13" && aws_lambda_function.main.handler == "handler.main"
    error_message = "The built-in Python handler must be deployed by default."
  }

  assert {
    condition     = length(data.archive_file.builtin) == 1 && endswith(aws_lambda_function.main.filename, "my-project-dev-function.zip")
    error_message = "The built-in handler must be packaged when no deployment package is given."
  }

  assert {
    condition     = aws_lambda_function.main.publish == true && aws_lambda_alias.live.name == "live"
    error_message = "Versions must be published for the live alias."
  }

  assert {
    condition     = aws_lambda_function.main.memory_size == 256 && aws_lambda_function.main.timeout == 30 && aws_lambda_function.main.tracing_config[0].mode == "Active"
    error_message = "Default memory, timeout and tracing are wrong."
  }

  assert {
    condition     = aws_lambda_function.main.environment[0].variables["ENVIRONMENT"] == "dev" && aws_lambda_function.main.environment[0].variables["PROJECT"] == "my-project"
    error_message = "ENVIRONMENT and PROJECT must be set on the function."
  }

  assert {
    condition     = length(aws_lambda_function.main.vpc_config) == 0 && length(aws_security_group.lambda) == 0 && output.security_group_id == null
    error_message = "The function is not attached to a VPC by default."
  }

  assert {
    condition     = aws_cloudwatch_log_group.lambda.name == "/aws/lambda/my-project-dev-function" && aws_cloudwatch_log_group.lambda.retention_in_days == 30
    error_message = "The function log group must be pre-created with retention."
  }

  assert {
    condition     = length(jsondecode(aws_iam_role_policy.lambda_secrets.policy).Statement) == 1
    error_message = "Without a KMS key the role must not get any KMS permission."
  }

  assert {
    condition     = aws_apigatewayv2_api.main[0].protocol_type == "HTTP" && aws_apigatewayv2_stage.main[0].name == "dev" && aws_apigatewayv2_route.default[0].route_key == "$default"
    error_message = "An HTTP API with a default route is created by default."
  }

  assert {
    condition     = aws_apigatewayv2_api.main[0].cors_configuration[0].allow_credentials == false
    error_message = "Credentials must not be allowed together with a wildcard origin."
  }

  assert {
    condition     = aws_apigatewayv2_stage.main[0].default_route_settings[0].throttling_burst_limit == 100 && aws_apigatewayv2_stage.main[0].default_route_settings[0].throttling_rate_limit == 50
    error_message = "Default throttling must be applied."
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.schedule) == 0 && length(aws_sqs_queue.main) == 0 && length(aws_lambda_provisioned_concurrency_config.main) == 0
    error_message = "Schedule, queue and provisioned concurrency are opt-in."
  }
}

run "vpc_kms_and_cors" {
  command = plan

  variables {
    enable_vpc           = true
    vpc_id               = "vpc-0123456789abcdef0"
    subnet_ids           = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    kms_key_arn          = "arn:aws:kms:eu-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
    cors_allowed_origins = ["https://app.example.com"]
    enable_xray          = false
    memory_size          = 1024
    timeout              = 60
    environment_variables = {
      LOG_LEVEL = "DEBUG"
    }
  }

  assert {
    condition     = length(aws_lambda_function.main.vpc_config[0].subnet_ids) == 2 && aws_security_group.lambda[0].vpc_id == "vpc-0123456789abcdef0"
    error_message = "The function must be attached to the given subnets with its own security group."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.lambda_vpc) == 1 && length(aws_iam_role_policy_attachment.lambda_xray) == 0
    error_message = "VPC access is attached and the X-Ray policy removed."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.lambda_vpc[0].cidr_ipv4 == "10.0.0.0/16" && aws_vpc_security_group_egress_rule.lambda_https[0].from_port == 443
    error_message = "Egress must be limited to the VPC and outbound HTTPS."
  }

  assert {
    condition     = aws_lambda_function.main.kms_key_arn == var.kms_key_arn && aws_cloudwatch_log_group.lambda.kms_key_id == var.kms_key_arn
    error_message = "The supplied key must encrypt environment variables and logs."
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.lambda_secrets.policy).Statement[1].Resource == var.kms_key_arn
    error_message = "KMS decrypt must be limited to the supplied key."
  }

  assert {
    condition     = aws_lambda_function.main.tracing_config[0].mode == "PassThrough" && aws_lambda_function.main.memory_size == 1024 && aws_lambda_function.main.timeout == 60
    error_message = "Tracing, memory and timeout must be applied."
  }

  assert {
    condition     = aws_lambda_function.main.environment[0].variables["LOG_LEVEL"] == "DEBUG"
    error_message = "Custom environment variables must be passed to the function."
  }

  assert {
    condition     = aws_apigatewayv2_api.main[0].cors_configuration[0].allow_credentials == true && aws_apigatewayv2_api.main[0].cors_configuration[0].allow_origins == toset(["https://app.example.com"])
    error_message = "Explicit origins must be applied and may use credentials."
  }
}

run "queue_schedule_and_concurrency" {
  command = plan

  variables {
    enable_api_gateway      = false
    enable_sqs              = true
    sqs_batch_size          = 5
    schedule_expression     = "rate(1 hour)"
    reserved_concurrency    = 10
    provisioned_concurrency = 2
  }

  assert {
    condition     = length(aws_apigatewayv2_api.main) == 0 && output.api_url == null
    error_message = "The API must be removable."
  }

  assert {
    condition     = aws_sqs_queue.main[0].name == "my-project-dev-queue" && aws_sqs_queue.main[0].visibility_timeout_seconds == 180 && aws_sqs_queue.main[0].sqs_managed_sse_enabled == true
    error_message = "The queue must be encrypted and use six times the function timeout as visibility timeout."
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 1 && aws_sqs_queue.dlq[0].sqs_managed_sse_enabled == true
    error_message = "An encrypted dead-letter queue is created by default."
  }

  assert {
    condition     = aws_lambda_event_source_mapping.sqs[0].batch_size == 5 && aws_lambda_event_source_mapping.sqs[0].function_response_types == toset(["ReportBatchItemFailures"])
    error_message = "The queue trigger must use the batch size and partial batch responses."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.schedule[0].schedule_expression == "rate(1 hour)" && aws_lambda_permission.eventbridge[0].principal == "events.amazonaws.com"
    error_message = "The schedule and its invoke permission must be created."
  }

  assert {
    condition     = aws_lambda_function.main.reserved_concurrent_executions == 10 && aws_lambda_provisioned_concurrency_config.main[0].provisioned_concurrent_executions == 2
    error_message = "Concurrency settings must be applied."
  }
}

run "queue_without_dlq" {
  command = plan

  variables {
    enable_sqs  = true
    enable_dlq  = false
    kms_key_arn = "arn:aws:kms:eu-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 0 && output.dlq_arn == null && output.dlq_url == null
    error_message = "enable_dlq = false must remove the dead-letter queue."
  }

  assert {
    condition     = aws_sqs_queue.main[0].kms_master_key_id == var.kms_key_arn
    error_message = "A supplied key must encrypt the queue."
  }
}

run "container_image" {
  command = plan

  variables {
    package_type = "Image"
    image_uri    = "123456789012.dkr.ecr.eu-west-2.amazonaws.com/my-project:1.0.0"
  }

  assert {
    condition     = aws_lambda_function.main.package_type == "Image" && aws_lambda_function.main.image_uri == var.image_uri
    error_message = "The container image must be deployed."
  }

  assert {
    condition     = aws_lambda_function.main.runtime == null && aws_lambda_function.main.handler == null && aws_lambda_function.main.filename == null && length(data.archive_file.builtin) == 0
    error_message = "Image functions take no runtime, handler or zip package."
  }
}

run "image_requires_uri" {
  command = plan

  variables {
    package_type = "Image"
  }

  expect_failures = [var.package_type]
}

run "vpc_requires_network" {
  command = plan

  variables {
    enable_vpc = true
  }

  expect_failures = [var.enable_vpc]
}

run "rejects_invalid_schedule" {
  command = plan

  variables {
    schedule_expression = "every hour"
  }

  expect_failures = [var.schedule_expression]
}
