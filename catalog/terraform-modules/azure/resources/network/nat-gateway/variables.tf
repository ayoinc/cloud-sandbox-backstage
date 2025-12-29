variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the NAT Gateway"
  type        = string
}

variable "location" {
  description = "The Azure region where the NAT Gateway will be created"
  type        = string
}

variable "name" {
  description = "The name suffix for the NAT Gateway"
  type        = string
}

variable "sku_name" {
  description = "The SKU name for the NAT Gateway and associated public IPs"
  type        = string
  default     = "Standard"
}

variable "idle_timeout_in_minutes" {
  description = "The idle timeout in minutes for the NAT Gateway"
  type        = number
  default     = 4

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 120
    error_message = "The idle timeout must be between 4 and 120 minutes."
  }
}

variable "zones" {
  description = "A list of availability zones where the NAT Gateway should be deployed"
  type        = list(string)
  default     = []
}

variable "public_ip_count" {
  description = "The number of public IP addresses to create and associate with the NAT Gateway"
  type        = number
  default     = 1

  validation {
    condition     = var.public_ip_count >= 1 && var.public_ip_count <= 16
    error_message = "The public IP count must be between 1 and 16."
  }
}

variable "use_public_ip_prefix" {
  description = "Whether to create and use a public IP prefix for the NAT Gateway"
  type        = bool
  default     = false
}

variable "public_ip_prefix_length" {
  description = "The prefix length for the public IP prefix (CIDR block size)"
  type        = number
  default     = 28

  validation {
    condition     = var.public_ip_prefix_length >= 24 && var.public_ip_prefix_length <= 31
    error_message = "The public IP prefix length must be between 24 and 31."
  }
}

variable "subnet_ids" {
  description = "A list of subnet IDs to associate with the NAT Gateway"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
