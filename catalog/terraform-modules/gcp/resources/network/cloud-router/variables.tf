variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The GCP region for the router"
  type        = string
}

variable "name" {
  description = "The name of the Cloud Router"
  type        = string
}

variable "network" {
  description = "The name or self_link of the network to attach the router to"
  type        = string
}

variable "description" {
  description = "An optional description of the Cloud Router"
  type        = string
  default     = null
}

variable "bgp_asn" {
  description = "Local BGP Autonomous System Number (ASN)"
  type        = number
  default     = 64514
}

variable "bgp_advertise_mode" {
  description = "BGP advertisement mode (DEFAULT or CUSTOM)"
  type        = string
  default     = "DEFAULT"

  validation {
    condition     = contains(["DEFAULT", "CUSTOM"], var.bgp_advertise_mode)
    error_message = "bgp_advertise_mode must be either DEFAULT or CUSTOM."
  }
}

variable "bgp_advertised_groups" {
  description = "List of prefix groups to advertise (only used when bgp_advertise_mode is CUSTOM)"
  type        = list(string)
  default     = []
}

variable "bgp_advertised_ip_ranges" {
  description = "List of custom IP ranges to advertise (only used when bgp_advertise_mode is CUSTOM)"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "bgp_keepalive_interval" {
  description = "The interval in seconds between BGP keepalive messages"
  type        = number
  default     = 20
}

variable "router_interfaces" {
  description = "List of router interfaces for VPN tunnels or interconnect attachments"
  type = list(object({
    name                    = string
    ip_range                = optional(string)
    vpn_tunnel              = optional(string)
    interconnect_attachment = optional(string)
    subnetwork              = optional(string)
  }))
  default = []
}

variable "router_peers" {
  description = "List of BGP peers for the router"
  type = list(object({
    name                      = string
    interface                 = string
    peer_ip_address           = string
    peer_asn                  = number
    advertised_route_priority = optional(number)
  }))
  default = []
}
