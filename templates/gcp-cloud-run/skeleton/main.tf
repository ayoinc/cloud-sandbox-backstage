# =============================================================================
# GCP Cloud Run - Root Configuration
# =============================================================================
# This is the main entry point that calls the Cloud Run module.
# Environment-specific values are provided via tfvars files.
# =============================================================================

module "cloud_run" {
  source = "./modules/cloud-run"

  # Required variables
  name        = var.name
  environment = var.environment
  region      = var.region
  project_id  = var.project_id
  owner       = var.owner
  labels      = var.labels

  # Container configuration
  container_image = var.container_image
  image_tag       = var.image_tag
  container_port  = var.container_port

  # Resource configuration
  cpu               = var.cpu
  memory            = var.memory
  cpu_idle          = var.cpu_idle
  startup_cpu_boost = var.startup_cpu_boost

  # Scaling configuration
  min_instances = var.min_instances
  max_instances = var.max_instances

  # Request configuration
  request_timeout       = var.request_timeout
  execution_environment = var.execution_environment

  # Ingress configuration
  ingress               = var.ingress
  allow_unauthenticated = var.allow_unauthenticated

  # Environment variables
  environment_variables        = var.environment_variables
  secret_environment_variables = var.secret_environment_variables

  # Volumes
  volume_mounts  = var.volume_mounts
  secret_volumes = var.secret_volumes

  # Health checks
  health_check_path                = var.health_check_path
  enable_startup_probe             = var.enable_startup_probe
  startup_probe_initial_delay      = var.startup_probe_initial_delay
  startup_probe_timeout            = var.startup_probe_timeout
  startup_probe_period             = var.startup_probe_period
  startup_probe_failure_threshold  = var.startup_probe_failure_threshold
  enable_liveness_probe            = var.enable_liveness_probe
  liveness_probe_initial_delay     = var.liveness_probe_initial_delay
  liveness_probe_timeout           = var.liveness_probe_timeout
  liveness_probe_period            = var.liveness_probe_period
  liveness_probe_failure_threshold = var.liveness_probe_failure_threshold

  # VPC configuration
  create_vpc_connector        = var.create_vpc_connector
  vpc_connector_network       = var.vpc_connector_network
  vpc_connector_cidr          = var.vpc_connector_cidr
  vpc_connector_min_instances = var.vpc_connector_min_instances
  vpc_connector_max_instances = var.vpc_connector_max_instances
  vpc_egress                  = var.vpc_egress

  # Service account
  service_account_roles = var.service_account_roles

  # Artifact Registry
  create_artifact_registry     = var.create_artifact_registry
  artifact_registry_keep_count = var.artifact_registry_keep_count

  # Monitoring
  enable_monitoring_alerts = var.enable_monitoring_alerts
  notification_channels    = var.notification_channels
  latency_threshold_ms     = var.latency_threshold_ms
  error_rate_threshold     = var.error_rate_threshold
  alert_duration_seconds   = var.alert_duration_seconds
}
