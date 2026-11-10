# =============================================================================
# Production Environment Configuration
# =============================================================================
# Full production settings with high availability and monitoring.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "prod"
description = ${{ (values.description or ('Lambda function for ' + values.name)) | dump | replace("${", "$${") | replace("%{", "%%{") }}

# Runtime Configuration
runtime = "${{ values.runtime }}"
handler = "${{ values.handler }}"

# Resource Configuration - Production optimized
memory_size = ${{ values.memory_size }}
timeout     = ${{ values.timeout }}

# Architecture
architectures = ["x86_64"]

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
  Owner       = "${{ values.owner }}"
  CostCenter  = "production"
  Application = "${{ values.name }}"
  Criticality = "High"
}
