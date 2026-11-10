# =============================================================================
# Azure VNet - Root Variables
# =============================================================================
# These variables are passed to the child module.
# Values are provided via environment-specific .tfvars files.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the VNet (used in resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "description" {
  description = "Description of the VNet purpose"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources (team or individual)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "address_space" {
  description = "CIDR block for the Virtual Network (/24 or larger; the subnets are carved out of it)"
  type        = string

  validation {
    condition     = can(cidrhost(var.address_space, 0)) && try(tonumber(split("/", var.address_space)[1]) <= 24, false)
    error_message = "Address space must be a valid CIDR block of /24 or larger."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (defaults to 1/16 of the address space)"
  type        = string
  default     = null
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (defaults to 1/16 of the address space)"
  type        = string
  default     = null
}

variable "database_subnet_cidr" {
  description = "CIDR block for the database subnet (defaults to 1/16 of the address space)"
  type        = string
  default     = null
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS subnet (defaults to 1/4 of the address space)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Optional Configuration
# -----------------------------------------------------------------------------

variable "dns_servers" {
  description = "List of custom DNS servers"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound connectivity"
  type        = bool
  default     = true
}

variable "nat_idle_timeout" {
  description = "NAT Gateway idle timeout in minutes"
  type        = number
  default     = 10
}

variable "availability_zones" {
  description = "Availability zones for zone-redundant resources"
  type        = list(string)
  default     = ["1"]
}

variable "enable_ddos_protection" {
  description = "Enable Azure DDoS Protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
