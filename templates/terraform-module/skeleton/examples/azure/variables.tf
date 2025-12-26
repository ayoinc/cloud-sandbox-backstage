variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "example"
}

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "azure_resource_group_name" {
  description = "Resource group name (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "azure_vnet_cidr" {
  description = "VNet CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
