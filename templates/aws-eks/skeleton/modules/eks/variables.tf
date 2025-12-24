# =============================================================================
# AWS EKS Module - Variables
# =============================================================================
# Input variables for the EKS module. These are passed from the root module.
# No Jinja2 template values - pure Terraform.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 40
    error_message = "Cluster name must be between 1 and 40 characters"
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "production", "development"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, production, development"
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster and node groups"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for high availability"
  }
}

# -----------------------------------------------------------------------------
# Optional Variables - Cluster Configuration
# -----------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"

  validation {
    condition     = can(regex("^1\\.(2[7-9]|3[0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.27 or higher"
  }
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -----------------------------------------------------------------------------
# Optional Variables - Node Group Configuration
# -----------------------------------------------------------------------------
variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Capacity type must be ON_DEMAND or SPOT"
  }
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "Desired size must be at least 1"
  }
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 1
    error_message = "Minimum size must be at least 1"
  }
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5

  validation {
    condition     = var.node_max_size >= 1
    error_message = "Maximum size must be at least 1"
  }
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

variable "node_labels" {
  description = "Key-value map of Kubernetes labels for node group"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "List of Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Optional Variables - Add-ons
# -----------------------------------------------------------------------------
variable "enable_cluster_autoscaler_irsa" {
  description = "Enable IRSA role for cluster autoscaler"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller_irsa" {
  description = "Enable IRSA role for AWS Load Balancer Controller"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Optional Variables - Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
