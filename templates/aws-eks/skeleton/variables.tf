# =============================================================================
# AWS EKS - Root Variables
# =============================================================================
# Variables for the root module. These are passed to the child EKS module.
# Values come from environments/*.tfvars files.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster and node groups"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Optional Variables - Cluster Configuration
# -----------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
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
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
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
