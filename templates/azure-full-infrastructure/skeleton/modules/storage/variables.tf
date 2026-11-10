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

variable "replication_type" {
  description = "Replication of the account: LRS, ZRS, GRS or GZRS"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Replication type must be one of: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  }
}

variable "enable_hierarchical_namespace" {
  description = "Enable the hierarchical namespace (Data Lake Storage Gen2)"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Days deleted blobs and containers stay recoverable"
  type        = number
  default     = 7
}

variable "restrict_network_access" {
  description = "Deny access to the account from networks other than the allowed subnets and IP ranges"
  type        = bool
  default     = false
}

variable "allowed_subnet_ids" {
  description = "Subnets allowed to reach the account (they need the Microsoft.Storage service endpoint)"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "Public IP addresses or CIDR ranges allowed to reach the account"
  type        = list(string)
  default     = []
}
