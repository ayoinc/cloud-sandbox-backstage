# -----------------------------------------------------------------------------
# AWS Kubernetes (EKS) Module - Variables
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

# Cluster Configuration
variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.28"
}

variable "enable_public_access" {
  description = "Enable public API endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks for public API access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_log_types" {
  description = "EKS control plane log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# Node Group Configuration
variable "node_instance_types" {
  description = "Node instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  type        = number
  default     = 50
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_labels" {
  description = "Node labels"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Node taints"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# Addons Configuration
variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
