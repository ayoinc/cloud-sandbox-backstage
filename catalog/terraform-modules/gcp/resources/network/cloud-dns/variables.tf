variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "zone_name" {
  description = "The name of the DNS zone"
  type        = string
}

variable "dns_name" {
  description = "The DNS name of this zone (must end with a dot)"
  type        = string

  validation {
    condition     = can(regex("\\.$", var.dns_name))
    error_message = "The dns_name must end with a trailing dot (e.g., 'example.com.')."
  }
}

variable "description" {
  description = "A description of the DNS zone"
  type        = string
  default     = null
}

variable "visibility" {
  description = "The zone's visibility: public or private"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.visibility)
    error_message = "The visibility must be either 'public' or 'private'."
  }
}

variable "private_visibility_config_networks" {
  description = "List of VPC network self-links for private zone visibility"
  type        = list(string)
  default     = []
}

variable "dnssec_state" {
  description = "The state of DNSSEC for public zones: on, off, or transfer"
  type        = string
  default     = "on"

  validation {
    condition     = contains(["on", "off", "transfer"], var.dnssec_state)
    error_message = "The dnssec_state must be one of: 'on', 'off', or 'transfer'."
  }
}

variable "forwarding_config_target_name_servers" {
  description = "List of target name servers for forwarding zones"
  type = list(object({
    ipv4_address    = string
    forwarding_path = optional(string)
  }))
  default = []
}

variable "peering_config_target_network" {
  description = "The network URL of the target VPC network for peering zones"
  type        = string
  default     = null
}

variable "records" {
  description = "List of DNS records to create in the zone"
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    rrdatas = list(string)
  }))
  default = []
}

variable "dns_policies" {
  description = "List of DNS policies to create"
  type = list(object({
    name                      = string
    enable_inbound_forwarding = optional(bool, false)
    enable_logging            = optional(bool, false)
    networks                  = optional(list(string))
    alternative_name_server_config = optional(object({
      target_name_servers = list(object({
        ipv4_address    = string
        forwarding_path = optional(string)
      }))
    }))
  }))
  default = []
}

variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}
