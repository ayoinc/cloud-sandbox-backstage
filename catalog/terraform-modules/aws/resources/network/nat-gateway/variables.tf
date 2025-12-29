variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs where NAT Gateways will be placed (one per AZ for HA)"
  type        = list(string)
}

variable "connectivity_type" {
  description = "Connectivity type for the NAT Gateway (public or private)"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.connectivity_type)
    error_message = "Connectivity type must be either 'public' or 'private'."
  }
}

variable "create_eip" {
  description = "Whether to create new Elastic IPs for the NAT Gateways (only applies when connectivity_type is public)"
  type        = bool
  default     = true
}

variable "allocation_ids" {
  description = "List of existing Elastic IP allocation IDs to use (only applies when create_eip is false and connectivity_type is public)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
