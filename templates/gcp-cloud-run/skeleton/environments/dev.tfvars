# =============================================================================
# GCP Cloud Run - Development Environment Configuration
# =============================================================================
# This file contains Jinja2 template variables that will be substituted
# by Backstage when the template is scaffolded.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "dev"
region      = "${{ values.region }}"
project_id  = "${{ values.gcpProject }}"
owner       = "${{ values.owner }}"

# -----------------------------------------------------------------------------
# Container Configuration
# -----------------------------------------------------------------------------
container_image = ""  # Uses Artifact Registry
image_tag       = "latest"
container_port  = 8080

# -----------------------------------------------------------------------------
# Resource Configuration - Development (minimal)
# -----------------------------------------------------------------------------
cpu               = "1"
memory            = "512Mi"
cpu_idle          = true
startup_cpu_boost = true

# -----------------------------------------------------------------------------
# Scaling Configuration - Development (cost-optimized)
# -----------------------------------------------------------------------------
min_instances = 0
max_instances = 3

# -----------------------------------------------------------------------------
# Request Configuration
# -----------------------------------------------------------------------------
request_timeout       = 300
execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

# -----------------------------------------------------------------------------
# Ingress Configuration - Development (allow all for testing)
# -----------------------------------------------------------------------------
ingress               = "INGRESS_TRAFFIC_ALL"
allow_unauthenticated = true

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------
environment_variables = {
  LOG_LEVEL = "debug"
  DEBUG     = "true"
}

# Secret environment variables
secret_environment_variables = {}

# -----------------------------------------------------------------------------
# Health Check Configuration
# -----------------------------------------------------------------------------
health_check_path               = "/health"
enable_startup_probe            = true
startup_probe_initial_delay     = 0
startup_probe_timeout           = 1
startup_probe_period            = 3
startup_probe_failure_threshold = 3
enable_liveness_probe           = true
liveness_probe_initial_delay    = 0
liveness_probe_timeout          = 1
liveness_probe_period           = 10
liveness_probe_failure_threshold = 3

# -----------------------------------------------------------------------------
# VPC Configuration - Disabled for dev
# -----------------------------------------------------------------------------
create_vpc_connector        = false
vpc_connector_network       = ""
vpc_connector_cidr          = "10.8.0.0/28"
vpc_connector_min_instances = 2
vpc_connector_max_instances = 3
vpc_egress                  = "PRIVATE_RANGES_ONLY"

# -----------------------------------------------------------------------------
# Service Account Configuration
# -----------------------------------------------------------------------------
service_account_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/cloudtrace.agent",
]

# -----------------------------------------------------------------------------
# Artifact Registry
# -----------------------------------------------------------------------------
create_artifact_registry     = true
artifact_registry_keep_count = 5

# -----------------------------------------------------------------------------
# Monitoring Configuration - Disabled for dev
# -----------------------------------------------------------------------------
enable_monitoring_alerts = false
notification_channels    = []
latency_threshold_ms     = 2000
error_rate_threshold     = 50
alert_duration_seconds   = 300

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------
labels = {
  cost-center = "development"
  team        = "${{ values.owner }}"
}
