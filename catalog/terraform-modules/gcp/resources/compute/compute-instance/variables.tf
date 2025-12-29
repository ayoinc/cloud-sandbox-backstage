variable "project_name" {
  description = "The name of the project for labeling purposes"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID where the instance will be created"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "zone" {
  description = "The GCP zone where the instance will be created"
  type        = string
}

variable "instance_name" {
  description = "The name of the compute instance"
  type        = string
}

variable "machine_type" {
  description = "The machine type for the instance"
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_image" {
  description = "The image to use for the boot disk"
  type        = string
}

variable "boot_disk_size_gb" {
  description = "The size of the boot disk in GB"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "The type of the boot disk (pd-standard, pd-balanced, pd-ssd)"
  type        = string
  default     = "pd-balanced"
}

variable "network" {
  description = "The VPC network to attach the instance to"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to attach the instance to"
  type        = string
}

variable "network_tags" {
  description = "Network tags to apply to the instance"
  type        = list(string)
  default     = []
}

variable "external_ip" {
  description = "Whether to assign an external IP address to the instance"
  type        = bool
  default     = false
}

variable "preemptible" {
  description = "Whether the instance is preemptible"
  type        = bool
  default     = false
}

variable "spot" {
  description = "Whether the instance is a Spot VM"
  type        = bool
  default     = false
}

variable "automatic_restart" {
  description = "Whether the instance should be automatically restarted if terminated"
  type        = bool
  default     = true
}

variable "on_host_maintenance" {
  description = "Action to take when host maintenance occurs (MIGRATE or TERMINATE)"
  type        = string
  default     = "MIGRATE"

  validation {
    condition     = contains(["MIGRATE", "TERMINATE"], var.on_host_maintenance)
    error_message = "on_host_maintenance must be either MIGRATE or TERMINATE."
  }
}

variable "service_account_email" {
  description = "The email of the service account to attach to the instance"
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "The scopes for the service account"
  type        = list(string)
  default     = ["cloud-platform"]
}

variable "metadata" {
  description = "Metadata key-value pairs to attach to the instance"
  type        = map(string)
  default     = {}
}

variable "metadata_startup_script" {
  description = "The startup script to run on instance boot"
  type        = string
  default     = null
}

variable "enable_shielded_vm" {
  description = "Whether to enable Shielded VM features"
  type        = bool
  default     = true
}

variable "enable_secure_boot" {
  description = "Whether to enable Secure Boot for Shielded VM"
  type        = bool
  default     = false
}

variable "enable_vtpm" {
  description = "Whether to enable vTPM for Shielded VM"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Whether to enable Integrity Monitoring for Shielded VM"
  type        = bool
  default     = true
}

variable "additional_disks" {
  description = "List of additional disks to attach to the instance"
  type = list(object({
    name    = string
    size_gb = number
    type    = string
    mode    = string
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default     = {}
}
