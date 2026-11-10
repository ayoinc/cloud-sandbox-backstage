# =============================================================================
# Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development/testing.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "dev"
description = ${{ (values.description or ('Lambda function for ' + values.name)) | dump | replace("${", "$${") | replace("%{", "%%{") }}

# Runtime Configuration
runtime = "${{ values.runtime }}"
handler = "${{ values.handler }}"

# Resource Configuration - Minimal for dev
memory_size = ${{ values.memory_size }}
timeout     = ${{ values.timeout }}

# Architecture
architectures = ["x86_64"]

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

# Trace only requests that an upstream service already sampled
tracing_mode = "PassThrough"

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
  Owner       = "${{ values.owner }}"
  CostCenter  = "development"
  Application = "${{ values.name }}"
}
