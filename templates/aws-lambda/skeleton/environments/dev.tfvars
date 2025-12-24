# =============================================================================
# Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development/testing.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "dev"
description = "${{ values.description | default('Lambda function for ' + values.name) }}"

# Runtime Configuration
runtime = "${{ values.runtime | default('python3.12') }}"
handler = "${{ values.handler | default('main.handler') }}"

# Resource Configuration - Minimal for dev
memory_size = 256
timeout     = 30

# Architecture
architectures = ["${{ values.architecture | default('x86_64') }}"]

# Ephemeral storage
ephemeral_storage_size = 512

# Logging - Short retention for dev
log_retention_days = 7

# No reserved concurrency in dev
reserved_concurrent_executions = -1

# Publish versions for tracking
publish_version = true

# Create alias for consistent invocation
create_alias = true

# No function URL in dev by default
create_function_url = false

# No X-Ray tracing in dev
tracing_mode = null

# No alarms in dev
create_error_alarm    = false
create_duration_alarm = false
create_throttle_alarm = false

# Environment variables
environment_variables = {
  LOG_LEVEL = "DEBUG"
}

# Tags
tags = {
  Project     = "${{ values.name }}"
  Owner       = "${{ values.owner | default('platform-team') }}"
  CostCenter  = "${{ values.cost_center | default('development') }}"
  Application = "${{ values.name }}"
}
