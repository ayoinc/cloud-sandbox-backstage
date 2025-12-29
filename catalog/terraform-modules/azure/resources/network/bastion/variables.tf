variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "name" {
  description = "The name of the Bastion host"
  type        = string
}

variable "sku" {
  description = "The SKU of the Bastion host (Basic or Standard)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "SKU must be either 'Basic' or 'Standard'."
  }
}

variable "subnet_id" {
  description = "The ID of the AzureBastionSubnet subnet"
  type        = string
}

variable "scale_units" {
  description = "The number of scale units for the Bastion host (2-50, Standard SKU only)"
  type        = number
  default     = 2

  validation {
    condition     = var.scale_units >= 2 && var.scale_units <= 50
    error_message = "Scale units must be between 2 and 50."
  }
}

variable "copy_paste_enabled" {
  description = "Enable copy/paste functionality"
  type        = bool
  default     = true
}

variable "file_copy_enabled" {
  description = "Enable file copy functionality (Standard SKU only)"
  type        = bool
  default     = false
}

variable "ip_connect_enabled" {
  description = "Enable IP-based connection (Standard SKU only)"
  type        = bool
  default     = false
}

variable "shareable_link_enabled" {
  description = "Enable shareable link functionality (Standard SKU only)"
  type        = bool
  default     = false
}

variable "tunneling_enabled" {
  description = "Enable native client tunneling (Standard SKU only)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
