#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------
variable "project_name" {
  description = "Name of the project"
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 64
    error_message = "Project name must be between 1 and 64 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "development", "staging", "uat", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, development, staging, uat, prod, production."
  }
}

variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.domain_name))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

#------------------------------------------------------------------------------
# Optional Variables
#------------------------------------------------------------------------------
variable "private_zone" {
  description = "Whether this is a private hosted zone"
  type        = bool
  default     = false
}

variable "vpc_ids" {
  description = "List of VPC IDs to associate with a private hosted zone"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for vpc_id in var.vpc_ids : can(regex("^vpc-[a-z0-9]+$", vpc_id))])
    error_message = "VPC IDs must be valid AWS VPC identifiers (e.g., vpc-12345678)."
  }
}

variable "records" {
  description = "List of DNS records to create in the hosted zone"
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string), [])
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }))
    weighted_routing = optional(object({
      weight = number
    }))
    latency_routing = optional(object({
      region = string
    }))
    geolocation_routing = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    set_identifier  = optional(string)
    health_check_id = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for record in var.records :
      contains(["A", "AAAA", "CAA", "CNAME", "DS", "MX", "NAPTR", "NS", "PTR", "SOA", "SPF", "SRV", "TXT"], record.type)
    ])
    error_message = "Record type must be one of: A, AAAA, CAA, CNAME, DS, MX, NAPTR, NS, PTR, SOA, SPF, SRV, TXT."
  }

  validation {
    condition = alltrue([
      for record in var.records :
      (record.alias != null) || (length(record.records) > 0)
    ])
    error_message = "Each record must have either an alias configuration or at least one record value."
  }

  validation {
    condition = alltrue([
      for record in var.records :
      (record.weighted_routing != null || record.latency_routing != null || record.geolocation_routing != null) ? record.set_identifier != null : true
    ])
    error_message = "Set identifier is required when using weighted, latency, or geolocation routing policies."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
