variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.project_name))
    error_message = "project_name must start with a lowercase letter and contain only lowercase letters, digits and hyphens (max 63 characters)."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,7}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits and start with a letter."
  }
}

variable "project_id" {
  description = "ID of the Google Cloud project that owns the resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID (6-30 lowercase letters, digits or hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region for regional resources."
  type        = string
}

variable "labels" {
  description = "Labels applied to every resource that supports them."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "zone" {
  description = "Primary zone of the instance group. Must be in region."
  type        = string
}

variable "additional_zones" {
  description = "Further zones in region across which instances are spread."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "network_name" {
  description = "Name of the VPC the instances attach to. Null uses the project's default network."
  type        = string
  default     = null
}

variable "subnet_name" {
  description = "Name of the subnet in region the instances attach to. Null lets the network pick its regional subnet (auto mode networks only)."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Machine type of the instances."
  type        = string
  default     = "e2-medium"
}

variable "source_image" {
  description = "Boot image or image family. The bundled startup script expects a Debian or Ubuntu image."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "boot_disk_size_gb" {
  description = "Size of the boot disk in GB."
  type        = number
  default     = 20

  validation {
    condition     = var.boot_disk_size_gb >= 10
    error_message = "boot_disk_size_gb must be at least 10."
  }
}

variable "boot_disk_type" {
  description = "Disk type of the boot and data disks."
  type        = string
  default     = "pd-balanced"

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd"], var.boot_disk_type)
    error_message = "boot_disk_type must be pd-standard, pd-balanced or pd-ssd."
  }
}

variable "data_disk_size_gb" {
  description = "Size in GB of an additional data disk attached as device data. 0 attaches none."
  type        = number
  default     = 0

  validation {
    condition     = var.data_disk_size_gb >= 0
    error_message = "data_disk_size_gb must not be negative."
  }
}

variable "kms_key_id" {
  description = "ID of a Cloud KMS key that encrypts the disks. The Compute Engine service agent must be allowed to use it. Null uses Google-managed encryption."
  type        = string
  default     = null
}

variable "enable_spot" {
  description = "Run the instances as Spot VMs, which are cheaper but can be stopped at any time."
  type        = bool
  default     = false
}

variable "metadata" {
  description = "Additional instance metadata. OS Login, project SSH key blocking, the serial port setting and the startup script are managed by the module."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "startup_script" {
  description = "Startup script run on boot. Null uses the bundled script, which installs the Ops Agent and an nginx site answering on app_port."
  type        = string
  default     = null
}

variable "service_account_roles" {
  description = "Project roles granted to the instance service account."
  type        = list(string)
  default     = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
  nullable    = false

  validation {
    condition     = alltrue([for r in var.service_account_roles : !contains(["roles/owner", "roles/editor"], r)])
    error_message = "The basic roles roles/owner and roles/editor are too broad for an instance service account."
  }
}

variable "app_port" {
  description = "Port the application listens on. Used by the named port http, the health check and the firewall rules."
  type        = number
  default     = 80

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "HTTP path probed by the health check. Null switches to a TCP check on app_port."
  type        = string
  default     = "/healthz"

  validation {
    condition     = var.health_check_path == null || can(regex("^/", var.health_check_path))
    error_message = "health_check_path must start with a slash."
  }
}

variable "auto_healing_initial_delay_sec" {
  description = "Seconds a new instance has to boot before failed health checks recreate it."
  type        = number
  default     = 300

  validation {
    condition     = var.auto_healing_initial_delay_sec >= 0 && var.auto_healing_initial_delay_sec <= 3600
    error_message = "auto_healing_initial_delay_sec must be between 0 and 3600."
  }
}

variable "min_replicas" {
  description = "Minimum number of instances."
  type        = number
  default     = 1

  validation {
    condition     = var.min_replicas >= 0
    error_message = "min_replicas must not be negative."
  }
}

variable "max_replicas" {
  description = "Maximum number of instances."
  type        = number
  default     = 3

  validation {
    condition     = var.max_replicas >= 1
    error_message = "max_replicas must be at least 1."
  }
}

variable "target_cpu_utilization" {
  description = "Average CPU utilization (0 to 1) the autoscaler maintains."
  type        = number
  default     = 0.6

  validation {
    condition     = var.target_cpu_utilization > 0 && var.target_cpu_utilization <= 1
    error_message = "target_cpu_utilization must be greater than 0 and at most 1."
  }
}

variable "autoscaler_cooldown_period" {
  description = "Seconds the autoscaler waits after an instance starts before using its metrics."
  type        = number
  default     = 120

  validation {
    condition     = var.autoscaler_cooldown_period >= 0
    error_message = "autoscaler_cooldown_period must not be negative."
  }
}

variable "enable_iap_ssh" {
  description = "Allow SSH to the instances through Identity-Aware Proxy TCP forwarding."
  type        = bool
  default     = true
}

variable "app_source_ranges" {
  description = "Source ranges allowed to reach app_port, such as a proxy-only subnet or an office range. Empty creates no rule."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for r in var.app_source_ranges : can(cidrhost(r, 0)) && r != "0.0.0.0/0"])
    error_message = "app_source_ranges must be valid CIDR blocks and must not include 0.0.0.0/0; publish the group through a load balancer instead."
  }
}
