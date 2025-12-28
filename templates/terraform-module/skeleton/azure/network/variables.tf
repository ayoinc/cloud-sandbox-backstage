# -----------------------------------------------------------------------------
# Azure Network Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "uat", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, uat, prod, production."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Name of existing resource group. If not provided, a new one will be created"
  type        = string
  default     = null
}

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "VNet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "subnet_count" {
  description = "Number of subnets per type (public, private, database)"
  type        = number
  default     = 3

  validation {
    condition     = var.subnet_count >= 1 && var.subnet_count <= 6
    error_message = "Subnet count must be between 1 and 6."
  }
}

variable "enable_nat" {
  description = "Enable NAT Gateway for private and database subnets"
  type        = bool
  default     = true
}

variable "nat_idle_timeout" {
  description = "Idle timeout in minutes for NAT Gateway"
  type        = number
  default     = 10

  validation {
    condition     = var.nat_idle_timeout >= 4 && var.nat_idle_timeout <= 120
    error_message = "NAT idle timeout must be between 4 and 120 minutes."
  }
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for NAT Gateway public IP"
  type        = bool
  default     = true
}

variable "enable_service_endpoints" {
  description = "Enable service endpoints on subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
