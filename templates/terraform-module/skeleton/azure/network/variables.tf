# -----------------------------------------------------------------------------
# Azure Network Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 2-40 characters of lowercase letters, numbers and hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.environment))
    error_message = "Environment must be 2-12 lowercase letters or numbers and start with a letter."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Name of an existing resource group. When null, the module creates rg-<project>-<environment>-network"
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

variable "subnet_newbits" {
  description = "Bits added to the VNet prefix length to size each subnet (4 turns a /16 VNet into /20 subnets)"
  type        = number
  default     = 4

  validation {
    condition     = var.subnet_newbits >= 2 && var.subnet_newbits <= 8
    error_message = "Subnet newbits must be between 2 and 8."
  }
}

variable "subnet_count" {
  description = "Number of subnets per tier (public, private, database, kubernetes). Azure subnets span all availability zones, so one per tier is normally enough"
  type        = number
  default     = 1

  validation {
    condition     = var.subnet_count >= 1 && var.subnet_count <= 4 && floor(var.subnet_count) == var.subnet_count
    error_message = "Subnet count must be a whole number between 1 and 4."
  }

  validation {
    condition     = 4 * var.subnet_count <= pow(2, var.subnet_newbits)
    error_message = "The four tiers need 4 x subnet_count subnets, which do not fit in 2^subnet_newbits. Increase subnet_newbits or lower subnet_count."
  }
}

variable "public_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the public subnets on the public ingress ports. Empty keeps the public subnets closed to the internet"
  type        = list(string)
  nullable    = false
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_ingress_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "Each public ingress entry must be a valid CIDR block and must not be a /0 range."
  }
}

variable "public_ingress_ports" {
  description = "TCP ports opened on the public subnets for public_ingress_cidrs"
  type        = list(number)
  nullable    = false
  default     = [80, 443]

  validation {
    condition     = length(var.public_ingress_ports) <= 10 && alltrue([for port in var.public_ingress_ports : port >= 1 && port <= 65535])
    error_message = "Provide at most 10 ports, each between 1 and 65535."
  }
}

variable "database_ports" {
  description = "TCP ports the private and kubernetes subnets may reach on the database subnets"
  type        = list(number)
  nullable    = false
  default     = [5432]

  validation {
    condition     = length(var.database_ports) >= 1 && alltrue([for port in var.database_ports : port >= 1 && port <= 65535])
    error_message = "Provide at least one port, each between 1 and 65535."
  }
}

variable "enable_nat" {
  description = "Create a NAT Gateway and attach it to the private and kubernetes subnets"
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
  description = "Make the NAT Gateway public IP zone-redundant. Disable in regions without availability zones"
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
  nullable    = false
  default     = {}
}
