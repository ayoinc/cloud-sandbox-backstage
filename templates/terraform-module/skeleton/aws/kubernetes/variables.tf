# -----------------------------------------------------------------------------
# AWS Kubernetes (EKS) Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as the prefix of every resource name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9._-]*$", var.project_name))
    error_message = "project_name must start with a letter and contain only letters, digits, dots, underscores and hyphens."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,8}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits."
  }
}

variable "vpc_id" {
  description = "ID of the VPC the cluster is placed in"
  type        = string

  validation {
    condition     = var.vpc_id != null
    error_message = "vpc_id is required. Enable the network module or pass an existing VPC."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs for the cluster"
  type        = list(string)

  validation {
    condition     = var.subnet_ids != null && length(coalesce(var.subnet_ids, [])) >= 2
    error_message = "subnet_ids must contain at least 2 subnet IDs in different availability zones."
  }
}

variable "create_kms_key" {
  description = "Create a dedicated KMS key for envelope encryption of Kubernetes secrets. Set to false to use kms_key_arn instead"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing KMS key ARN. Encrypts the control plane log group (its key policy must allow CloudWatch Logs) and, when create_kms_key is false, Kubernetes secrets"
  type        = string
  default     = null
}

# Cluster Configuration
variable "cluster_version" {
  description = "Kubernetes version (for example \"1.34\"). Null uses the current EKS default version"
  type        = string
  default     = null

  validation {
    condition     = var.cluster_version == null || can(regex("^1\\.[0-9]{2}$", coalesce(var.cluster_version, "1.00")))
    error_message = "cluster_version must look like 1.34."
  }
}

variable "enable_public_access" {
  description = "Expose the Kubernetes API endpoint on the internet, restricted to public_access_cidrs. The private endpoint is always enabled"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_public_access || length(var.public_access_cidrs) > 0
    error_message = "public_access_cidrs must list the networks allowed to reach the API when enable_public_access is true."
  }
}

variable "public_access_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the public API endpoint. Only used when enable_public_access is true"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_access_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "public_access_cidrs must be valid IPv4 CIDR blocks and must not include 0.0.0.0/0."
  }
}

variable "private_access_cidrs" {
  description = "IPv4 CIDR blocks inside the private network (VPN, CI runners, bastion) allowed to reach the private API endpoint"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.private_access_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "private_access_cidrs must be valid IPv4 CIDR blocks and must not include 0.0.0.0/0."
  }
}

variable "enabled_log_types" {
  description = "EKS control plane log types sent to CloudWatch Logs"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition     = alltrue([for t in var.enabled_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)])
    error_message = "enabled_log_types may only contain api, audit, authenticator, controllerManager and scheduler."
  }
}

# Node Group Configuration
variable "node_instance_types" {
  description = "Instance types of the managed node group"
  type        = list(string)
  default     = ["t3.medium"]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "node_instance_types must contain at least one instance type."
  }
}

variable "node_ami_type" {
  description = "EKS optimised AMI type of the nodes; must match the architecture of node_instance_types"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  description = "Node root volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.node_disk_size >= 20
    error_message = "node_disk_size must be at least 20 GB."
  }
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 0 && var.node_min_size <= var.node_max_size
    error_message = "node_min_size must be between 0 and node_max_size."
  }
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5

  validation {
    condition     = var.node_max_size >= 1
    error_message = "node_max_size must be at least 1."
  }
}

variable "node_desired_size" {
  description = "Initial number of nodes. Later changes made by an autoscaler are kept"
  type        = number
  default     = 2

  validation {
    condition     = var.node_desired_size >= var.node_min_size && var.node_desired_size <= var.node_max_size
    error_message = "node_desired_size must be between node_min_size and node_max_size."
  }
}

variable "node_labels" {
  description = "Kubernetes labels applied to the nodes"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Kubernetes taints applied to the nodes"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []

  validation {
    condition     = alltrue([for t in var.node_taints : contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], t.effect)])
    error_message = "Taint effect must be NO_SCHEDULE, NO_EXECUTE or PREFER_NO_SCHEDULE."
  }
}

# Addons Configuration
variable "enable_ebs_csi_driver" {
  description = "Install the EBS CSI driver addon with its own IAM role"
  type        = bool
  default     = true
}

# Logging
variable "log_retention_days" {
  description = "Retention in days of the control plane log group"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
