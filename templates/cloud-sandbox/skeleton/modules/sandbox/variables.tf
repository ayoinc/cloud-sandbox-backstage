# =============================================================================
# Cloud Sandbox Module - Variables
# =============================================================================

variable "name" {
  description = "Name of the sandbox environment"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnets" {
  description = "Number of public subnets"
  type        = number
}

variable "private_subnets" {
  description = "Number of private subnets"
  type        = number
}

variable "include_bastion" {
  description = "Include a bastion host"
  type        = bool
  default     = false
}

variable "include_eks" {
  description = "Include an EKS cluster"
  type        = bool
  default     = false
}

variable "include_rds" {
  description = "Include an RDS database"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
