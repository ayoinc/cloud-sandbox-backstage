# =============================================================================
# AWS Lambda Terraform Tests
# =============================================================================
# These tests validate the Lambda function configuration using the module
# structure. Tests use root module outputs to validate behavior.
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Mock Providers - Prevent actual AWS API calls
# -----------------------------------------------------------------------------
mock_provider "aws" {
  alias = "mock"
}

mock_provider "archive" {
  alias = "mock"
}

# =============================================================================
# UNIT TESTS - Lambda Function Configuration
# =============================================================================

run "lambda_function_basic_config" {
  command = plan

  variables {
    name        = "test-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.function_name == "test-lambda-dev"
    error_message = "Lambda function name must match the expected pattern: name-environment"
  }

  assert {
    condition     = output.runtime == "python3.12"
    error_message = "Lambda runtime must be set correctly"
  }

  assert {
    condition     = output.handler == "main.handler"
    error_message = "Lambda handler must be set correctly"
  }
}

run "lambda_memory_configuration" {
  command = plan

  variables {
    name        = "test-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.memory_size == 256
    error_message = "Lambda memory size must be 256 MB"
  }
}

run "lambda_timeout_configuration" {
  command = plan

  variables {
    name        = "test-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.timeout == 30
    error_message = "Lambda timeout must be 30 seconds"
  }
}

run "lambda_environment_variable" {
  command = plan

  variables {
    name        = "test-lambda"
    environment = "staging"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.environment == "staging"
    error_message = "Lambda must have ENVIRONMENT set correctly"
  }
}

# =============================================================================
# IAM ROLE TESTS
# =============================================================================

run "lambda_iam_role_configuration" {
  command = plan

  variables {
    name        = "test-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.role_name == "test-lambda-dev-role"
    error_message = "Lambda IAM role name must follow naming convention"
  }

  assert {
    condition     = output.role_arn != null
    error_message = "Lambda IAM role ARN must be defined"
  }
}

# =============================================================================
# CLOUDWATCH LOGS TESTS
# =============================================================================

run "cloudwatch_log_group_configuration" {
  command = plan

  variables {
    name        = "test-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.log_group_name == "/aws/lambda/test-lambda-dev"
    error_message = "CloudWatch log group must follow Lambda naming convention"
  }
}

# =============================================================================
# RUNTIME VALIDATION TESTS
# =============================================================================

run "python_runtime" {
  command = plan

  variables {
    name        = "py-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.runtime == "python3.12"
    error_message = "Python runtime should be 3.12"
  }
}

run "nodejs_runtime" {
  command = plan

  variables {
    name        = "node-lambda"
    environment = "dev"
    runtime     = "nodejs22.x"
    handler     = "index.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.runtime == "nodejs22.x"
    error_message = "Node.js runtime should be 22.x"
  }
}

run "java_runtime" {
  command = plan

  variables {
    name        = "java-lambda"
    environment = "dev"
    runtime     = "java21"
    handler     = "com.example.Handler::handleRequest"
    memory_size = 512
    timeout     = 60
  }

  assert {
    condition     = output.runtime == "java21"
    error_message = "Java runtime should be 21"
  }
}

# =============================================================================
# MEMORY SIZE VALIDATION TESTS
# =============================================================================

run "minimum_memory" {
  command = plan

  variables {
    name        = "min-mem-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 128
    timeout     = 30
  }

  assert {
    condition     = output.memory_size == 128
    error_message = "Lambda should accept minimum memory of 128 MB"
  }
}

run "large_memory_configuration" {
  command = plan

  variables {
    name        = "large-mem-lambda"
    environment = "prod"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 1024
    timeout     = 60
  }

  assert {
    condition     = output.memory_size == 1024
    error_message = "Lambda should accept 1024 MB memory"
  }
}

run "maximum_memory" {
  command = plan

  variables {
    name        = "max-mem-lambda"
    environment = "prod"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 10240
    timeout     = 60
  }

  assert {
    condition     = output.memory_size == 10240
    error_message = "Lambda should accept maximum memory of 10,240 MB"
  }
}

# =============================================================================
# TIMEOUT VALIDATION TESTS
# =============================================================================

run "quick_function_timeout" {
  command = plan

  variables {
    name        = "quick-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 3
  }

  assert {
    condition     = output.timeout == 3
    error_message = "Lambda should accept short timeout of 3 seconds"
  }
}

run "long_function_timeout" {
  command = plan

  variables {
    name        = "long-lambda"
    environment = "prod"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 512
    timeout     = 300
  }

  assert {
    condition     = output.timeout == 300
    error_message = "Lambda should accept 5 minute timeout"
  }
}

run "maximum_timeout" {
  command = plan

  variables {
    name        = "max-timeout-lambda"
    environment = "prod"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 512
    timeout     = 900
  }

  assert {
    condition     = output.timeout == 900
    error_message = "Lambda should accept maximum timeout of 900 seconds (15 minutes)"
  }
}

# =============================================================================
# OUTPUT VALIDATION TESTS
# =============================================================================

run "outputs_are_defined" {
  command = plan

  variables {
    name        = "output-test-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.function_name != null
    error_message = "Function name output must be defined"
  }

  assert {
    condition     = output.function_arn != null
    error_message = "Function ARN output must be defined"
  }

  assert {
    condition     = output.invoke_arn != null
    error_message = "Invoke ARN output must be defined"
  }

  assert {
    condition     = output.role_arn != null
    error_message = "Role ARN output must be defined"
  }

  assert {
    condition     = output.log_group_name != null
    error_message = "Log group name output must be defined"
  }
}

# =============================================================================
# ENVIRONMENT CONFIGURATION TESTS
# =============================================================================

run "development_environment" {
  command = plan

  variables {
    name        = "dev-lambda"
    environment = "dev"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 256
    timeout     = 30
  }

  assert {
    condition     = output.environment == "dev"
    error_message = "Development environment should be set correctly"
  }

  assert {
    condition     = output.function_name == "dev-lambda-dev"
    error_message = "Development function name should follow pattern"
  }
}

run "staging_environment" {
  command = plan

  variables {
    name        = "staging-lambda"
    environment = "staging"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 512
    timeout     = 60
  }

  assert {
    condition     = output.environment == "staging"
    error_message = "Staging environment should be set correctly"
  }

  assert {
    condition     = output.function_name == "staging-lambda-staging"
    error_message = "Staging function name should follow pattern"
  }
}

run "production_environment" {
  command = plan

  variables {
    name        = "prod-lambda"
    environment = "prod"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 1024
    timeout     = 60
  }

  assert {
    condition     = output.environment == "prod"
    error_message = "Production environment should be set correctly"
  }

  assert {
    condition     = output.memory_size >= 512
    error_message = "Production Lambda should have at least 512 MB memory"
  }
}

# =============================================================================
# FUNCTION INFO SUMMARY TESTS
# =============================================================================

run "function_info_summary" {
  command = plan

  variables {
    name        = "summary-test"
    environment = "staging"
    runtime     = "python3.12"
    handler     = "main.handler"
    memory_size = 512
    timeout     = 45
  }

  assert {
    condition     = output.function_info.name == "summary-test-staging"
    error_message = "Function info name should match function_name"
  }

  assert {
    condition     = output.function_info.runtime == "python3.12"
    error_message = "Function info should show runtime"
  }

  assert {
    condition     = output.function_info.memory_size == 512
    error_message = "Function info should show memory size"
  }

  assert {
    condition     = output.function_info.timeout == 45
    error_message = "Function info should show timeout"
  }
}
