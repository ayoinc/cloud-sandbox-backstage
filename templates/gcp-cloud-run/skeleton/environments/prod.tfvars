{%- set selected = values.environment == 'production' -%}
# =============================================================================
# GCP Cloud Run - Production Environment Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "prod"
region      = "${{ values.region }}"
project_id  = "${{ values.gcpProject }}"
owner       = "${{ (values.owner | parseEntityRef).name }}"

# -----------------------------------------------------------------------------
# Container Configuration
# -----------------------------------------------------------------------------
container_image = "" # Uses Artifact Registry
image_tag       = "latest"
container_port  = 8080

# -----------------------------------------------------------------------------
# Resource Configuration - Production (higher resources)
# -----------------------------------------------------------------------------
cpu               = "${{ values.cpu if selected else '2' }}"
memory            = "${{ values.memory if selected else '2Gi' }}"
cpu_idle          = false # Keep CPU warm for consistent latency
startup_cpu_boost = true

# -----------------------------------------------------------------------------
# Scaling Configuration - Production (higher capacity)
# -----------------------------------------------------------------------------
min_instances = 2
max_instances = ${{ values.maxInstances if selected else 20 }}

# -----------------------------------------------------------------------------
# Request Configuration
# -----------------------------------------------------------------------------
request_timeout       = 300
execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

# -----------------------------------------------------------------------------
# Ingress Configuration - Production (internal only recommended)
# -----------------------------------------------------------------------------
ingress               = "INGRESS_TRAFFIC_ALL"
allow_unauthenticated = ${{ values.allowUnauthenticated if selected else false }}

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------
environment_variables = {
  LOG_LEVEL = "warn"
  DEBUG     = "false"
}

# Secret environment variables - Example configuration
# Uncomment and configure as needed
# secret_environment_variables = {
#   DATABASE_PASSWORD = {
#     secret_name = "database-password"
#     version     = "latest"
#   }
#   API_KEY = {
#     secret_name = "api-key"
#     version     = "latest"
#   }
# }
secret_environment_variables = {}

# -----------------------------------------------------------------------------
# Health Check Configuration
# -----------------------------------------------------------------------------
health_check_path                = "/health"
enable_startup_probe             = true
startup_probe_initial_delay      = 0
startup_probe_timeout            = 1
startup_probe_period             = 3
startup_probe_failure_threshold  = 3
enable_liveness_probe            = true
liveness_probe_initial_delay     = 0
liveness_probe_timeout           = 1
liveness_probe_period            = 10
liveness_probe_failure_threshold = 3

# -----------------------------------------------------------------------------
# VPC Configuration - Enable for production if needed
# -----------------------------------------------------------------------------
# Uncomment and configure for private networking
# create_vpc_connector        = true
# vpc_connector_network       = "projects/PROJECT/global/networks/VPC"
# vpc_connector_cidr          = "10.8.0.0/28"
# vpc_connector_min_instances = 2
# vpc_connector_max_instances = 10
# vpc_egress                  = "ALL_TRAFFIC"
create_vpc_connector        = false
vpc_connector_network       = ""
vpc_connector_cidr          = "10.8.0.0/28"
vpc_connector_min_instances = 2
vpc_connector_max_instances = 10
vpc_egress                  = "PRIVATE_RANGES_ONLY"

# -----------------------------------------------------------------------------
# Service Account Configuration
# -----------------------------------------------------------------------------
service_account_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/cloudtrace.agent",
  "roles/secretmanager.secretAccessor",
]

# -----------------------------------------------------------------------------
# Artifact Registry
# -----------------------------------------------------------------------------
create_artifact_registry     = true
artifact_registry_keep_count = 20

# -----------------------------------------------------------------------------
# Monitoring Configuration - Enabled for production
# -----------------------------------------------------------------------------
enable_monitoring_alerts = true
notification_channels    = [] # Add notification channel IDs
latency_threshold_ms     = 1000
error_rate_threshold     = 10
alert_duration_seconds   = 300

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------
labels = {
  cost-center = "production"
  team        = "${{ (values.owner | parseEntityRef).name }}"
  criticality = "high"
}
