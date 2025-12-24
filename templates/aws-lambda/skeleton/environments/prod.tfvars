# =============================================================================
# Production Environment Configuration
# =============================================================================
# Full production settings with high availability and monitoring.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "prod"
description = "${{ values.description | default('Lambda function for ' + values.name) }}"

# Runtime Configuration
runtime = "${{ values.runtime | default('python3.12') }}"
handler = "${{ values.handler | default('main.handler') }}"

# Resource Configuration - Production optimized
memory_size = 1024
timeout     = 60

# Architecture
architectures = ["${{ values.architecture | default('x86_64') }}"]

# Ephemeral storage - More space for production workloads
ephemeral_storage_size = 1024

# Logging - Extended retention for compliance
log_retention_days = 90

# Production concurrency - Higher limits
reserved_concurrent_executions = 500

# Publish versions for tracking and rollback
publish_version = true

# Create alias for blue/green deployments
create_alias = true

# Function URL disabled by default for security
create_function_url    = false
function_url_auth_type = "AWS_IAM"

# Enable active X-Ray tracing for production observability
tracing_mode = "Active"

# Full alarm configuration for production
create_error_alarm       = true
error_alarm_threshold    = 1
create_duration_alarm    = true
duration_alarm_threshold = 5000
create_throttle_alarm    = true
throttle_alarm_threshold = 1

# Environment variables
environment_variables = {
  LOG_LEVEL = "WARNING"
}

# Tags
tags = {
  Project     = "${{ values.name }}"
  Owner       = "${{ values.owner | default('platform-team') }}"
  CostCenter  = "${{ values.cost_center | default('production') }}"
  Application = "${{ values.name }}"
  Criticality = "High"
}
