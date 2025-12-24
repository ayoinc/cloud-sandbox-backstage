# =============================================================================
# GCP Cloud Run Module - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the Cloud Run service (used in resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Name must be 3-63 characters, lowercase alphanumeric and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "development", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, development, production."
  }
}

variable "region" {
  description = "GCP region for Cloud Run service"
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region (e.g., us-central1, europe-west1)."
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# -----------------------------------------------------------------------------
# Optional Metadata
# -----------------------------------------------------------------------------

variable "owner" {
  description = "Owner of the Cloud Run resources"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Container Configuration
# -----------------------------------------------------------------------------

variable "container_image" {
  description = "Full container image URL. If empty, uses Artifact Registry image."
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "Container image tag (used when container_image is empty)"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

# -----------------------------------------------------------------------------
# Resource Configuration
# -----------------------------------------------------------------------------

variable "cpu" {
  description = "CPU allocation for each container instance"
  type        = string
  default     = "1"

  validation {
    condition     = contains(["1", "2", "4", "6", "8"], var.cpu)
    error_message = "CPU must be 1, 2, 4, 6, or 8."
  }
}

variable "memory" {
  description = "Memory allocation for each container instance"
  type        = string
  default     = "512Mi"
}

variable "cpu_idle" {
  description = "Allow CPU to idle when no requests are being processed"
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Boost CPU during startup"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Scaling Configuration
# -----------------------------------------------------------------------------

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0 && var.min_instances <= 100
    error_message = "Minimum instances must be between 0 and 100."
  }
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10

  validation {
    condition     = var.max_instances >= 1 && var.max_instances <= 1000
    error_message = "Maximum instances must be between 1 and 1000."
  }
}

# -----------------------------------------------------------------------------
# Request Configuration
# -----------------------------------------------------------------------------

variable "request_timeout" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300

  validation {
    condition     = var.request_timeout >= 1 && var.request_timeout <= 3600
    error_message = "Request timeout must be between 1 and 3600 seconds."
  }
}

variable "execution_environment" {
  description = "Execution environment (EXECUTION_ENVIRONMENT_GEN1 or EXECUTION_ENVIRONMENT_GEN2)"
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"

  validation {
    condition     = contains(["EXECUTION_ENVIRONMENT_GEN1", "EXECUTION_ENVIRONMENT_GEN2"], var.execution_environment)
    error_message = "Execution environment must be EXECUTION_ENVIRONMENT_GEN1 or EXECUTION_ENVIRONMENT_GEN2."
  }
}

# -----------------------------------------------------------------------------
# Ingress Configuration
# -----------------------------------------------------------------------------

variable "ingress" {
  description = "Ingress settings (INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER)"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "Ingress must be INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  }
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated invocations (public access)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

variable "environment_variables" {
  description = "Environment variables to set in the container"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret Manager secrets to expose as environment variables"
  type = map(object({
    secret_name = string
    version     = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Volumes and Secrets
# -----------------------------------------------------------------------------

variable "volume_mounts" {
  description = "Volume mounts (name => mount_path)"
  type        = map(string)
  default     = {}
}

variable "secret_volumes" {
  description = "Secret Manager secrets to mount as volumes"
  type = map(object({
    secret_name = string
    path        = string
    version     = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Health Check Configuration
# -----------------------------------------------------------------------------

variable "health_check_path" {
  description = "Path for health check probes"
  type        = string
  default     = "/health"
}

variable "enable_startup_probe" {
  description = "Enable startup probe"
  type        = bool
  default     = true
}

variable "startup_probe_initial_delay" {
  description = "Initial delay for startup probe in seconds"
  type        = number
  default     = 0
}

variable "startup_probe_timeout" {
  description = "Timeout for startup probe in seconds"
  type        = number
  default     = 1
}

variable "startup_probe_period" {
  description = "Period between startup probes in seconds"
  type        = number
  default     = 3
}

variable "startup_probe_failure_threshold" {
  description = "Number of failures before startup probe fails"
  type        = number
  default     = 3
}

variable "enable_liveness_probe" {
  description = "Enable liveness probe"
  type        = bool
  default     = true
}

variable "liveness_probe_initial_delay" {
  description = "Initial delay for liveness probe in seconds"
  type        = number
  default     = 0
}

variable "liveness_probe_timeout" {
  description = "Timeout for liveness probe in seconds"
  type        = number
  default     = 1
}

variable "liveness_probe_period" {
  description = "Period between liveness probes in seconds"
  type        = number
  default     = 10
}

variable "liveness_probe_failure_threshold" {
  description = "Number of failures before liveness probe fails"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------

variable "create_vpc_connector" {
  description = "Create a VPC Access Connector for private networking"
  type        = bool
  default     = false
}

variable "vpc_connector_network" {
  description = "VPC network for the connector"
  type        = string
  default     = ""
}

variable "vpc_connector_cidr" {
  description = "CIDR range for the VPC connector"
  type        = string
  default     = "10.8.0.0/28"
}

variable "vpc_connector_min_instances" {
  description = "Minimum instances for VPC connector"
  type        = number
  default     = 2
}

variable "vpc_connector_max_instances" {
  description = "Maximum instances for VPC connector"
  type        = number
  default     = 3
}

variable "vpc_egress" {
  description = "VPC egress setting (ALL_TRAFFIC or PRIVATE_RANGES_ONLY)"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_egress)
    error_message = "VPC egress must be ALL_TRAFFIC or PRIVATE_RANGES_ONLY."
  }
}

# -----------------------------------------------------------------------------
# Service Account Configuration
# -----------------------------------------------------------------------------

variable "service_account_roles" {
  description = "IAM roles to grant to the Cloud Run service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

# -----------------------------------------------------------------------------
# Artifact Registry Configuration
# -----------------------------------------------------------------------------

variable "create_artifact_registry" {
  description = "Create an Artifact Registry for container images"
  type        = bool
  default     = true
}

variable "artifact_registry_keep_count" {
  description = "Number of container image versions to keep in Artifact Registry"
  type        = number
  default     = 10

  validation {
    condition     = var.artifact_registry_keep_count >= 1 && var.artifact_registry_keep_count <= 100
    error_message = "Artifact Registry keep count must be between 1 and 100."
  }
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "enable_monitoring_alerts" {
  description = "Enable Cloud Monitoring alert policies"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "Notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "latency_threshold_ms" {
  description = "P99 latency threshold in milliseconds for alerts"
  type        = number
  default     = 1000
}

variable "error_rate_threshold" {
  description = "Error rate threshold per minute for alerts"
  type        = number
  default     = 10
}

variable "alert_duration_seconds" {
  description = "Duration in seconds before alert fires"
  type        = number
  default     = 300
}
