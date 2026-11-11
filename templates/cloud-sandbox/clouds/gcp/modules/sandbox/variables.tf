variable "project_id" {
  description = "ID of the Google Cloud project the sandbox is created in."
  type        = string
}

variable "name" {
  description = "Name of the sandbox; prefixes every resource."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "The name may contain only lowercase letters, digits and hyphens."
  }
}

variable "region" {
  description = "Google Cloud region the sandbox is created in."
  type        = string
}

variable "vpc_cidr" {
  description = "Address range of the VPC network. Subnets are /4 slices of it, so it can be at most a /24."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrsubnet(var.vpc_cidr, 8, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block with a prefix of /24 or shorter."
  }
}

variable "public_subnets" {
  description = "Number of public subnets."
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnets >= 1 && var.public_subnets <= 4
    error_message = "public_subnets must be between 1 and 4."
  }
}

variable "private_subnets" {
  description = "Number of private subnets. At least one is created when GKE is included, because its nodes run there."
  type        = number
  default     = 2

  validation {
    condition     = var.private_subnets >= 0 && var.private_subnets <= 4
    error_message = "private_subnets must be between 0 and 4."
  }
}

variable "include_bastion" {
  description = "Create a bastion VM reachable through Identity-Aware Proxy."
  type        = bool
  default     = false
}

variable "include_eks" {
  description = "Create a GKE Autopilot cluster."
  type        = bool
  default     = false
}

variable "kubernetes_api_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the GKE API from the internet. Empty allows the VPC network only."
  type        = list(string)
  default     = []
}

variable "include_rds" {
  description = "Create a Cloud SQL for PostgreSQL instance."
  type        = bool
  default     = false
}
