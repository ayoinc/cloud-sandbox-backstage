variable "name" {
  description = "Name prefix for all resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "create_resource_group" {
  description = "Create a new resource group"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of existing resource group (if create_resource_group is false)"
  type        = string
  default     = ""
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNet"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "public_subnet_service_endpoints" {
  description = "Service endpoints for public subnets"
  type        = list(string)
  default     = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

variable "private_subnet_service_endpoints" {
  description = "Service endpoints for private subnets"
  type        = list(string)
  default     = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
}

variable "enable_private_endpoints" {
  description = "Enable private endpoint network policies"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "Availability zones for zone-redundant resources"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure VM access"
  type        = bool
  default     = false
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for Azure Bastion subnet"
  type        = string
  default     = "10.0.255.0/27"
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings for VNet"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
