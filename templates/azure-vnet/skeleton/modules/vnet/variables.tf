# =============================================================================
# Azure VNet Module - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the VNet (used in resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Name must be 3-63 characters, lowercase alphanumeric and hyphens, start and end with alphanumeric."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "development", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, development, production."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string

  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3",
      "centralus", "northcentralus", "southcentralus",
      "westeurope", "northeurope", "uksouth", "ukwest",
      "germanywestcentral", "francecentral", "switzerlandnorth",
      "australiaeast", "australiasoutheast", "japaneast", "japanwest",
      "southeastasia", "eastasia", "koreacentral", "koreasouth",
      "canadacentral", "canadaeast", "brazilsouth",
      "southafricanorth", "uaenorth"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "address_space" {
  description = "CIDR block for the Virtual Network (e.g., 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.address_space, 0))
    error_message = "Address space must be a valid CIDR block."
  }
}

# -----------------------------------------------------------------------------
# Subnet CIDRs
# -----------------------------------------------------------------------------

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid CIDR block."
  }
}

variable "database_subnet_cidr" {
  description = "CIDR block for the database subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.database_subnet_cidr, 0))
    error_message = "Database subnet CIDR must be a valid CIDR block."
  }
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS subnet (should be larger, e.g., /20)"
  type        = string

  validation {
    condition     = can(cidrhost(var.aks_subnet_cidr, 0))
    error_message = "AKS subnet CIDR must be a valid CIDR block."
  }
}

# -----------------------------------------------------------------------------
# Optional Variables
# -----------------------------------------------------------------------------

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

variable "dns_servers" {
  description = "List of custom DNS servers (leave empty for Azure default)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound connectivity from private subnets"
  type        = bool
  default     = true
}

variable "nat_idle_timeout" {
  description = "NAT Gateway idle timeout in minutes (4-120)"
  type        = number
  default     = 10

  validation {
    condition     = var.nat_idle_timeout >= 4 && var.nat_idle_timeout <= 120
    error_message = "NAT idle timeout must be between 4 and 120 minutes."
  }
}

variable "availability_zones" {
  description = "Availability zones for zone-redundant resources"
  type        = list(string)
  default     = ["1"]

  validation {
    condition     = length(var.availability_zones) > 0 && alltrue([for z in var.availability_zones : contains(["1", "2", "3"], z)])
    error_message = "Availability zones must be a non-empty list containing values 1, 2, or 3."
  }
}

variable "enable_ddos_protection" {
  description = "Enable Azure DDoS Protection (additional cost)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
