# =============================================================================
# Staging Environment Configuration
# =============================================================================
# Production-like settings for staging/QA environment.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "staging"
description = "${{ values.description | default('Lambda function for ' + values.name) }}"

# Runtime Configuration
runtime = "${{ values.runtime | default('python3.12') }}"
handler = "${{ values.handler | default('main.handler') }}"

# Resource Configuration - Moderate for staging
memory_size = 512
timeout     = 60

# Architecture
architectures = ["${{ values.architecture | default('x86_64') }}"]

# Ephemeral storage
ephemeral_storage_size = 512

# Logging - Moderate retention
log_retention_days = 14

# Limited concurrency for staging
reserved_concurrent_executions = 100

# Publish versions for tracking
publish_version = true

# Create alias for consistent invocation
create_alias = true

# Enable function URL for testing
create_function_url    = false
function_url_auth_type = "AWS_IAM"

# Enable X-Ray tracing
tracing_mode = "PassThrough"

# Basic alarms in staging
create_error_alarm       = true
error_alarm_threshold    = 5
create_duration_alarm    = true
duration_alarm_threshold = 10000
create_throttle_alarm    = true
throttle_alarm_threshold = 10

# Environment variables
environment_variables = {
  LOG_LEVEL = "INFO"
}

# Tags
tags = {
  Project     = "${{ values.name }}"
  Owner       = "${{ values.owner | default('platform-team') }}"
  CostCenter  = "${{ values.cost_center | default('staging') }}"
  Application = "${{ values.name }}"
}
