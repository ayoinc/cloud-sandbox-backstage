variable "project_name" {
  description = "The name of the project for labeling purposes"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The GCP region for the instance group"
  type        = string
}

variable "name" {
  description = "The name of the instance group manager"
  type        = string
}

variable "machine_type" {
  description = "The machine type for instances"
  type        = string
  default     = "e2-medium"
}

variable "source_image" {
  description = "The source image for the boot disk"
  type        = string
}

variable "disk_size_gb" {
  description = "The size of the boot disk in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "The type of the boot disk"
  type        = string
  default     = "pd-balanced"
}

variable "network" {
  description = "The VPC network for the instances"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork for the instances"
  type        = string
}

variable "network_tags" {
  description = "Network tags to apply to instances"
  type        = list(string)
  default     = []
}

variable "service_account_email" {
  description = "The service account email to attach to instances"
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "The scopes for the service account"
  type        = list(string)
  default     = ["cloud-platform"]
}

variable "metadata" {
  description = "Metadata key-value pairs to attach to instances"
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "The startup script to run on instance boot"
  type        = string
  default     = null
}

variable "target_size" {
  description = "The target number of instances (ignored if autoscaling is enabled)"
  type        = number
  default     = 2
}

variable "base_instance_name" {
  description = "The base name for instances in the group"
  type        = string
}

variable "distribution_policy_zones" {
  description = "The zones for distributing instances"
  type        = list(string)
  default     = null
}

variable "named_ports" {
  description = "Named ports for load balancer integration"
  type = list(object({
    name = string
    port = number
  }))
  default = []
}

variable "auto_healing_health_check" {
  description = "The health check self_link for auto-healing"
  type        = string
  default     = null
}

variable "initial_delay_sec" {
  description = "Initial delay before health checking for auto-healing"
  type        = number
  default     = 300
}

variable "enable_autoscaling" {
  description = "Whether to enable autoscaling"
  type        = bool
  default     = true
}

variable "min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 10
}

variable "cpu_target" {
  description = "Target CPU utilization for autoscaling (0.0 to 1.0)"
  type        = number
  default     = 0.6
}

variable "cooldown_period" {
  description = "Cooldown period in seconds for autoscaling"
  type        = number
  default     = 60
}

variable "update_type" {
  description = "The type of update process (PROACTIVE or OPPORTUNISTIC)"
  type        = string
  default     = "PROACTIVE"
}

variable "max_surge_fixed" {
  description = "Maximum number of instances that can be created above target during update"
  type        = number
  default     = 1
}

variable "max_unavailable_fixed" {
  description = "Maximum number of instances that can be unavailable during update"
  type        = number
  default     = 0
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
