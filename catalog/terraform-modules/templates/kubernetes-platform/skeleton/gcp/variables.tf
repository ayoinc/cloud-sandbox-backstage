# Values chosen when this repository was created are in terraform.tfvars.
# The variables of the platform components are in variables-platform.tf.

variable "project_name" {
  description = "Name of the project, used as a prefix for resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name)) && length(var.project_name) <= 16
    error_message = "project_name must be at most 16 lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment this stack belongs to"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging or production."
  }
}

variable "gcp_project_id" {
  description = "ID of the Google Cloud project the resources are created in"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.gcp_project_id))
    error_message = "gcp_project_id must be a project ID: 6 to 30 lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "region" {
  description = "Google Cloud region of the network and the regional cluster"
  type        = string
}

# --- Network ------------------------------------------------------------------

variable "subnet_cidr" {
  description = "Primary range of the cluster subnet. Nodes get their addresses from it."
  type        = string
  default     = "10.0.0.0/20"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be an IPv4 CIDR block."
  }
}

variable "pods_cidr" {
  description = "Secondary range of the cluster subnet for pods. Every node takes a /24 of it."
  type        = string
  default     = "10.4.0.0/14"

  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "pods_cidr must be an IPv4 CIDR block."
  }
}

variable "services_cidr" {
  description = "Secondary range of the cluster subnet for Kubernetes Services"
  type        = string
  default     = "10.8.0.0/20"

  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "services_cidr must be an IPv4 CIDR block."
  }
}

variable "master_ipv4_cidr_block" {
  description = "A /28 for the internal endpoint of the control plane. It must not overlap any range of the network."
  type        = string
  default     = "172.16.0.0/28"

  validation {
    condition     = can(cidrhost(var.master_ipv4_cidr_block, 0)) && endswith(var.master_ipv4_cidr_block, "/28")
    error_message = "master_ipv4_cidr_block must be a /28 IPv4 CIDR block."
  }
}

variable "control_plane_webhook_ports" {
  description = "TCP ports on which the control plane may call admission webhooks running on the nodes, besides 443 and 10250 that GKE opens itself. The defaults cover ingress-nginx and Gatekeeper (8443), Istio (15017) and operators built with controller-runtime (9443)."
  type        = list(string)
  default     = ["8443", "9443", "15017"]
}

# --- Cluster ------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes minor version the control plane is created with, for example 1.36. GKE installs the newest patch release of it and upgrades the cluster automatically afterwards."
  type        = string

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be a minor version such as 1.36."
  }
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR, STABLE or EXTENDED. When null, GKE enrols the cluster in the most mature channel that offers kubernetes_version."
  type        = string
  default     = null

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "EXTENDED"], coalesce(var.release_channel, "REGULAR"))
    error_message = "release_channel must be RAPID, REGULAR, STABLE, EXTENDED or null."
  }
}

variable "maintenance_start_time" {
  description = "Start of the daily four-hour window for automatic upgrades, HH:MM in UTC"
  type        = string
  default     = "02:00"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_start_time))
    error_message = "maintenance_start_time must be a time such as 02:00."
  }
}

# --- Nodes --------------------------------------------------------------------

variable "node_min_count" {
  description = "Smallest number of nodes in the cluster, over all zones"
  type        = number

  validation {
    condition     = var.node_min_count >= 1 && floor(var.node_min_count) == var.node_min_count
    error_message = "node_min_count must be a whole number of at least 1."
  }
}

variable "node_max_count" {
  description = "Largest number of nodes the cluster autoscaler may scale the node pool to, over all zones. A value below node_min_count counts as node_min_count."
  type        = number

  validation {
    condition     = var.node_max_count >= 1 && floor(var.node_max_count) == var.node_max_count
    error_message = "node_max_count must be a whole number of at least 1."
  }
}

variable "node_size" {
  description = "Size of the nodes: small (2 vCPU, 4 GB), medium (4 vCPU, 16 GB) or large (8 vCPU, 32 GB)"
  type        = string

  validation {
    condition     = contains(["small", "medium", "large"], var.node_size)
    error_message = "node_size must be small, medium or large."
  }
}

variable "node_disk_size_gb" {
  description = "Size of the boot disk of every node in GB"
  type        = number
  default     = 100
}
