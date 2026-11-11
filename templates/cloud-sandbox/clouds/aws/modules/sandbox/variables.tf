variable "name" {
  description = "Name of the sandbox; prefixes every resource."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "The name may contain only lowercase letters, digits and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC. Subnets are /4 slices of it, so it can be at most a /24."
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
  description = "Number of private subnets. At least two are created when EKS or RDS is included, because both need two availability zones."
  type        = number
  default     = 2

  validation {
    condition     = var.private_subnets >= 0 && var.private_subnets <= 4
    error_message = "private_subnets must be between 0 and 4."
  }
}

variable "include_bastion" {
  description = "Create a bastion host reachable through AWS Systems Manager Session Manager."
  type        = bool
  default     = false
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the bastion on SSH (22). Empty means Session Manager only."
  type        = list(string)
  default     = []
}

variable "include_eks" {
  description = "Create an EKS cluster with one managed node group."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version of the EKS cluster. Null uses the current EKS default."
  type        = string
  default     = null
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the EKS API from the internet. Empty keeps the API private to the VPC."
  type        = list(string)
  default     = []
}

variable "include_rds" {
  description = "Create a PostgreSQL RDS instance."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}
