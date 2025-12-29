variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "zone" {
  description = "The zone where the Filestore instance will be created"
  type        = string
}

variable "name" {
  description = "The name of the Filestore instance"
  type        = string
}

variable "description" {
  description = "A description of the Filestore instance"
  type        = string
  default     = null
}

variable "tier" {
  description = "The service tier of the Filestore instance"
  type        = string
  default     = "BASIC_HDD"

  validation {
    condition     = contains(["BASIC_HDD", "BASIC_SSD", "HIGH_SCALE_SSD", "ENTERPRISE"], var.tier)
    error_message = "Tier must be one of: BASIC_HDD, BASIC_SSD, HIGH_SCALE_SSD, ENTERPRISE."
  }
}

variable "file_shares" {
  description = "File share configuration for the Filestore instance"
  type = list(object({
    name        = string
    capacity_gb = number
    nfs_export_options = optional(list(object({
      ip_ranges   = list(string)
      access_mode = optional(string, "READ_WRITE")
      squash_mode = optional(string, "NO_ROOT_SQUASH")
      anon_uid    = optional(number)
      anon_gid    = optional(number)
    })))
  }))
}

variable "network" {
  description = "The name of the VPC network to connect the Filestore instance to"
  type        = string
}

variable "connect_mode" {
  description = "The network connect mode of the Filestore instance"
  type        = string
  default     = "DIRECT_PEERING"

  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "Connect mode must be one of: DIRECT_PEERING, PRIVATE_SERVICE_ACCESS."
  }
}

variable "reserved_ip_range" {
  description = "A reserved IP range for the Filestore instance"
  type        = string
  default     = null
}

variable "kms_key_name" {
  description = "The KMS key name for CMEK encryption"
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to the Filestore instance"
  type        = map(string)
  default     = {}
}
