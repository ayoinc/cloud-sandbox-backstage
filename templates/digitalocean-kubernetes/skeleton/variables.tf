# =============================================================================
# DigitalOcean Kubernetes - Variables
# =============================================================================

variable "name" {
  description = "Name used in resource names; the environment is appended."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "Use lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment: dev, staging or prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "region" {
  description = "DigitalOcean region of the cluster and the VPC."
  type        = string
}

variable "description" {
  description = "Purpose of the cluster, shown on the DigitalOcean project and the VPC."
  type        = string
}

variable "owner" {
  description = "Team that owns the cluster, added as a tag."
  type        = string
}

# -----------------------------------------------------------------------------
# Cluster
# -----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes minor version, for instance 1.37. The latest patch release DigitalOcean offers is used."
  type        = string

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.kubernetes_version))
    error_message = "Give the minor version only, for instance 1.37."
  }
}

variable "ha_control_plane" {
  description = "Run a highly available control plane. It cannot be turned off again."
  type        = bool
  default     = false
}

variable "auto_upgrade" {
  description = "Install new patch releases during the maintenance window."
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "Start of the weekly maintenance window, in UTC."
  type = object({
    day        = string
    start_time = string
  })
  default = {
    day        = "sunday"
    start_time = "03:00"
  }
}

variable "control_plane_allowed_cidrs" {
  description = "Addresses allowed to reach the Kubernetes API. An empty list leaves the API reachable from anywhere (it still requires authentication)."
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "Address range of the VPC. It must not overlap other VPCs of the account."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "The VPC range must be a CIDR block."
  }
}

# -----------------------------------------------------------------------------
# Node pools
# -----------------------------------------------------------------------------

variable "node_size" {
  description = "Droplet size of the default node pool."
  type        = string
}

variable "min_nodes" {
  description = "Fewest nodes the autoscaler keeps in the default node pool."
  type        = number

  validation {
    condition     = var.min_nodes >= 1
    error_message = "The default node pool needs at least one node."
  }
}

variable "max_nodes" {
  description = "Most nodes the autoscaler adds to the default node pool."
  type        = number

  validation {
    condition     = var.max_nodes >= var.min_nodes
    error_message = "max_nodes must not be smaller than min_nodes."
  }
}

variable "additional_node_pools" {
  description = "Further autoscaling node pools, keyed by name."
  type = map(object({
    size      = string
    min_nodes = number
    max_nodes = number
    labels    = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Container registry
# -----------------------------------------------------------------------------

variable "registry_integration" {
  description = "Let the cluster pull images from the container registry of the account. A registry must exist."
  type        = bool
  default     = true
}

variable "create_registry" {
  description = "Create the container registry. Leave false when the account already has one."
  type        = bool
  default     = false
}

variable "registry_name" {
  description = "Name of the registry to create. Registry names are unique across DigitalOcean."
  type        = string
  default     = null
}

variable "registry_tier" {
  description = "Subscription tier of the registry to create: starter, basic or professional."
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["starter", "basic", "professional"], var.registry_tier)
    error_message = "The registry tier must be starter, basic or professional."
  }
}
