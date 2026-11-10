variable "name" {
  description = "Project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the resources of this module"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "restrict_network_access" {
  description = "Deny access to the vault from networks other than the allowed subnets and IP ranges"
  type        = bool
  default     = false
}

variable "allowed_subnet_ids" {
  description = "Subnets allowed to reach the vault (they need the Microsoft.KeyVault service endpoint)"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "Public IP addresses or CIDR ranges allowed to reach the vault"
  type        = list(string)
  default     = []
}
