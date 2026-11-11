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

variable "network_name" {
  description = "Name of the VPC the cluster attaches to. Null uses the project's default network."
  type        = string
  default     = null
}

variable "subnet_name" {
  description = "Name of the subnet in region for nodes. Null lets GKE use the network's subnet for the region (auto mode networks only)."
  type        = string
  default     = null
}

variable "pods_range_name" {
  description = "Name of an existing secondary range on the subnet for pods. Null lets GKE create one."
  type        = string
  default     = null
}

variable "services_range_name" {
  description = "Name of an existing secondary range on the subnet for services. Null lets GKE create one."
  type        = string
  default     = null
}

variable "enable_autopilot" {
  description = "Create an Autopilot cluster, where Google manages the nodes. False creates a Standard cluster with a system pool and the pools in node_pools."
  type        = bool
  default     = true
}

variable "release_channel" {
  description = "Release channel that upgrades the cluster automatically: RAPID, REGULAR, STABLE or EXTENDED."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "EXTENDED"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, STABLE or EXTENDED."
  }
}

variable "deletion_protection" {
  description = "Prevent Terraform from deleting the cluster."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Expose the control plane only on its internal address. False adds a public endpoint restricted to master_authorized_networks."
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "Ranges allowed to reach the control plane, in addition to the cluster's own subnet. Required when enable_private_endpoint is false."
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for n in var.master_authorized_networks : can(cidrhost(n.cidr_block, 0)) && n.cidr_block != "0.0.0.0/0"])
    error_message = "master_authorized_networks must contain valid CIDR blocks and must not include 0.0.0.0/0."
  }
}

variable "master_ipv4_cidr_block" {
  description = "A /28 range for the control plane's internal endpoint. Null lets GKE allocate it."
  type        = string
  default     = null

  validation {
    condition     = var.master_ipv4_cidr_block == null || can(regex("/28$", var.master_ipv4_cidr_block)) && can(cidrhost(var.master_ipv4_cidr_block, 0))
    error_message = "master_ipv4_cidr_block must be a valid /28 CIDR block."
  }
}

variable "kms_key_id" {
  description = "ID of a Cloud KMS key in region that encrypts Kubernetes secrets and the image repository. The GKE and Artifact Registry service agents must be allowed to use it. Null uses Google-managed encryption."
  type        = string
  default     = null
}

variable "maintenance_start_time" {
  description = "Start of the daily maintenance window in UTC, HH:MM."
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_start_time))
    error_message = "maintenance_start_time must use the 24-hour HH:MM format."
  }
}

variable "system_node_count" {
  description = "Standard clusters only: nodes per zone in the default pool that runs system workloads."
  type        = number
  default     = 1

  validation {
    condition     = var.system_node_count >= 1 && floor(var.system_node_count) == var.system_node_count
    error_message = "system_node_count must be a whole number of at least 1."
  }
}

variable "system_machine_type" {
  description = "Standard clusters only: machine type of the default pool."
  type        = string
  default     = "e2-standard-2"
}

variable "node_pools" {
  description = "Standard clusters only: workload node pools keyed by name. Counts are per zone. Taint effects are NO_SCHEDULE, PREFER_NO_SCHEDULE or NO_EXECUTE."
  type = map(object({
    machine_type = optional(string, "e2-standard-4")
    min_count    = optional(number, 1)
    max_count    = optional(number, 3)
    disk_size_gb = optional(number, 100)
    disk_type    = optional(string, "pd-balanced")
    spot         = optional(bool, false)
    labels       = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for name, pool in var.node_pools : can(regex("^[a-z]([a-z0-9-]{0,38}[a-z0-9])?$", name)) && pool.max_count >= pool.min_count && pool.min_count >= 0])
    error_message = "Node pool names must be lowercase (max 40 characters) and max_count must be at least min_count."
  }
}

variable "enable_artifact_registry" {
  description = "Create an Artifact Registry Docker repository that the nodes can pull from."
  type        = bool
  default     = true
}

variable "artifact_registry_immutable_tags" {
  description = "Prevent image tags from being moved to another digest."
  type        = bool
  default     = true
}

variable "artifact_registry_keep_count" {
  description = "Number of most recent versions of each image the cleanup policy always keeps."
  type        = number
  default     = 10

  validation {
    condition     = var.artifact_registry_keep_count >= 1
    error_message = "artifact_registry_keep_count must be at least 1."
  }
}

variable "artifact_registry_untagged_retention_days" {
  description = "Days after which untagged image versions are deleted."
  type        = number
  default     = 30

  validation {
    condition     = var.artifact_registry_untagged_retention_days >= 1 && floor(var.artifact_registry_untagged_retention_days) == var.artifact_registry_untagged_retention_days
    error_message = "artifact_registry_untagged_retention_days must be a whole number of at least 1."
  }
}
