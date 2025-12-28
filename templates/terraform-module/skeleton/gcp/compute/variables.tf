# -----------------------------------------------------------------------------
# GCP Compute Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project and Environment
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone (for zonal resources)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_self_link" {
  description = "Self link of the VPC network"
  type        = string
}

variable "subnetwork_self_link" {
  description = "Self link of the subnetwork"
  type        = string
}

variable "enable_external_ip" {
  description = "Enable external IP addresses for instances"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Instance Configuration
# -----------------------------------------------------------------------------

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-medium"
}

variable "source_image" {
  description = "Source image for boot disk (leave empty for Debian 12)"
  type        = string
  default     = ""
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.boot_disk_size_gb >= 10
    error_message = "Boot disk size must be at least 10 GB."
  }
}

variable "boot_disk_type" {
  description = "Boot disk type (pd-standard, pd-balanced, pd-ssd)"
  type        = string
  default     = "pd-balanced"

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd", "pd-extreme"], var.boot_disk_type)
    error_message = "Boot disk type must be one of: pd-standard, pd-balanced, pd-ssd, pd-extreme."
  }
}

variable "data_disk_size_gb" {
  description = "Additional data disk size in GB (0 to disable)"
  type        = number
  default     = 0
}

variable "data_disk_type" {
  description = "Data disk type"
  type        = string
  default     = "pd-balanced"
}

variable "preemptible" {
  description = "Use preemptible (spot) instances"
  type        = bool
  default     = false
}

variable "metadata" {
  description = "Additional metadata for instances"
  type        = map(string)
  default     = {}
}

variable "enable_os_login" {
  description = "Enable OS Login for SSH access"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Shielded Instance Configuration
# -----------------------------------------------------------------------------

variable "enable_secure_boot" {
  description = "Enable Secure Boot for shielded instances"
  type        = bool
  default     = true
}

variable "enable_vtpm" {
  description = "Enable vTPM for shielded instances"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring for shielded instances"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Auto Scaling Configuration
# -----------------------------------------------------------------------------

variable "min_replicas" {
  description = "Minimum number of instances"
  type        = number
  default     = 1

  validation {
    condition     = var.min_replicas >= 0
    error_message = "Minimum replicas must be at least 0."
  }
}

variable "max_replicas" {
  description = "Maximum number of instances"
  type        = number
  default     = 3

  validation {
    condition     = var.max_replicas >= 1
    error_message = "Maximum replicas must be at least 1."
  }
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for autoscaling (0.0 to 1.0)"
  type        = number
  default     = 0.6

  validation {
    condition     = var.target_cpu_utilization > 0 && var.target_cpu_utilization <= 1
    error_message = "Target CPU utilization must be between 0 and 1."
  }
}

variable "target_load_balancing_utilization" {
  description = "Target load balancing utilization for autoscaling"
  type        = number
  default     = null
}

variable "autoscaler_cooldown_period" {
  description = "Cooldown period in seconds"
  type        = number
  default     = 60
}

variable "predictive_autoscaling_mode" {
  description = "Predictive autoscaling mode (NONE, OPTIMIZE_AVAILABILITY)"
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "OPTIMIZE_AVAILABILITY"], var.predictive_autoscaling_mode)
    error_message = "Predictive autoscaling mode must be NONE or OPTIMIZE_AVAILABILITY."
  }
}

variable "autoscaling_metrics" {
  description = "Custom metrics for autoscaling"
  type = list(object({
    name   = string
    type   = string
    target = number
  }))
  default = []
}

variable "autoscaler_mode" {
  description = "Autoscaler mode (ON, OFF, ONLY_SCALE_OUT)"
  type        = string
  default     = "ON"

  validation {
    condition     = contains(["ON", "OFF", "ONLY_SCALE_OUT"], var.autoscaler_mode)
    error_message = "Autoscaler mode must be ON, OFF, or ONLY_SCALE_OUT."
  }
}

variable "scale_in_control_max_replicas" {
  description = "Maximum number of instances that can be scaled in at once"
  type        = number
  default     = 1
}

variable "scale_in_control_time_window_sec" {
  description = "Time window for scale-in control in seconds"
  type        = number
  default     = 600
}

variable "scaling_schedules" {
  description = "Scheduled scaling configurations"
  type = map(object({
    description           = string
    min_required_replicas = number
    schedule              = string
    time_zone             = string
    duration_sec          = number
    disabled              = bool
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Instance Group Manager Configuration
# -----------------------------------------------------------------------------

variable "distribution_policy_zones" {
  description = "Zones for instance distribution"
  type        = list(string)
  default     = []
}

variable "distribution_policy_target_shape" {
  description = "Target shape for distribution (EVEN, BALANCED, ANY)"
  type        = string
  default     = "EVEN"

  validation {
    condition     = contains(["EVEN", "BALANCED", "ANY", "ANY_SINGLE_ZONE"], var.distribution_policy_target_shape)
    error_message = "Distribution policy target shape must be EVEN, BALANCED, ANY, or ANY_SINGLE_ZONE."
  }
}

variable "target_pools" {
  description = "Target pools for load balancing"
  type        = list(string)
  default     = []
}

variable "named_ports" {
  description = "Named ports for load balancing"
  type = list(object({
    name = string
    port = number
  }))
  default = [
    {
      name = "http"
      port = 80
    }
  ]
}

variable "auto_healing_initial_delay_sec" {
  description = "Initial delay before auto-healing checks"
  type        = number
  default     = 300
}

variable "update_policy_type" {
  description = "Update policy type (PROACTIVE, OPPORTUNISTIC)"
  type        = string
  default     = "PROACTIVE"

  validation {
    condition     = contains(["PROACTIVE", "OPPORTUNISTIC"], var.update_policy_type)
    error_message = "Update policy type must be PROACTIVE or OPPORTUNISTIC."
  }
}

variable "update_policy_minimal_action" {
  description = "Minimal action for update policy (NONE, REFRESH, RESTART, REPLACE)"
  type        = string
  default     = "REPLACE"
}

variable "update_policy_most_disruptive_action" {
  description = "Most disruptive action allowed (NONE, REFRESH, RESTART, REPLACE)"
  type        = string
  default     = "REPLACE"
}

variable "update_policy_max_surge_fixed" {
  description = "Maximum number of instances that can be created above target"
  type        = number
  default     = 1
}

variable "update_policy_max_unavailable_fixed" {
  description = "Maximum number of instances that can be unavailable"
  type        = number
  default     = 1
}

variable "update_policy_replacement_method" {
  description = "Replacement method (RECREATE, SUBSTITUTE)"
  type        = string
  default     = "SUBSTITUTE"

  validation {
    condition     = contains(["RECREATE", "SUBSTITUTE"], var.update_policy_replacement_method)
    error_message = "Update policy replacement method must be RECREATE or SUBSTITUTE."
  }
}

variable "stateful_disks" {
  description = "Stateful disk configurations"
  type = list(object({
    device_name = string
    delete_rule = string
  }))
  default = []
}

variable "node_affinities" {
  description = "Node affinities for sole-tenant nodes"
  type = list(object({
    key      = string
    operator = string
    values   = list(string)
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Health Check Configuration
# -----------------------------------------------------------------------------

variable "health_check_type" {
  description = "Health check type (HTTP, HTTPS, TCP)"
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.health_check_type)
    error_message = "Health check type must be HTTP, HTTPS, or TCP."
  }
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for HTTP/HTTPS health checks"
  type        = string
  default     = "/health"
}

variable "health_check_interval_sec" {
  description = "Health check interval in seconds"
  type        = number
  default     = 10
}

variable "health_check_timeout_sec" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of successful checks for healthy status"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of failed checks for unhealthy status"
  type        = number
  default     = 3
}

variable "enable_health_check_logging" {
  description = "Enable health check logging"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Service Account Configuration
# -----------------------------------------------------------------------------

variable "service_account_roles" {
  description = "IAM roles to assign to the service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer"
  ]
}

variable "service_account_scopes" {
  description = "OAuth scopes for the service account"
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}

# -----------------------------------------------------------------------------
# Firewall Configuration
# -----------------------------------------------------------------------------

variable "internal_source_ranges" {
  description = "Internal source ranges for firewall rules"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "enable_ssh_firewall" {
  description = "Enable SSH firewall rule"
  type        = bool
  default     = false
}

variable "ssh_source_ranges" {
  description = "Source ranges for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "enable_http_firewall" {
  description = "Enable HTTP/HTTPS firewall rule"
  type        = bool
  default     = true
}

variable "http_source_ranges" {
  description = "Source ranges for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "custom_firewall_rules" {
  description = "Custom firewall rules"
  type = map(object({
    description   = string
    direction     = string
    priority      = number
    source_ranges = list(string)
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Tags and Labels
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Network tags for instances"
  type        = list(string)
  default     = ["compute-instance"]
}

variable "labels" {
  description = "Labels for all resources"
  type        = map(string)
  default     = {}
}
