variable "name" {
  description = "Name prefix for all resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "GLOBAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be REGIONAL or GLOBAL."
  }
}

variable "delete_default_routes" {
  description = "Delete default routes when VPC is created"
  type        = bool
  default     = false
}

variable "mtu" {
  description = "Maximum Transmission Unit in bytes"
  type        = number
  default     = 1460

  validation {
    condition     = var.mtu >= 1300 && var.mtu <= 8896
    error_message = "MTU must be between 1300 and 8896."
  }
}

variable "public_subnets" {
  description = "List of public subnet configurations"
  type = list(object({
    region = string
    cidr   = string
    secondary_ranges = optional(list(object({
      name = string
      cidr = string
    })), [])
  }))
  default = [
    {
      region = "us-central1"
      cidr   = "10.0.1.0/24"
    }
  ]
}

variable "private_subnets" {
  description = "List of private subnet configurations"
  type = list(object({
    region = string
    cidr   = string
    secondary_ranges = optional(list(object({
      name = string
      cidr = string
    })), [])
  }))
  default = [
    {
      region = "us-central1"
      cidr   = "10.0.11.0/24"
    }
  ]
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for subnets"
  type        = bool
  default     = true
}

variable "flow_logs_interval" {
  description = "Aggregation interval for flow logs"
  type        = string
  default     = "INTERVAL_5_SEC"
}

variable "flow_logs_sampling" {
  description = "Sampling rate for flow logs (0.0 to 1.0)"
  type        = number
  default     = 0.5
}

variable "flow_logs_metadata" {
  description = "Metadata to include in flow logs"
  type        = string
  default     = "INCLUDE_ALL_METADATA"
}

variable "enable_nat" {
  description = "Enable Cloud NAT for private subnets"
  type        = bool
  default     = true
}

variable "nat_region" {
  description = "Region for Cloud NAT"
  type        = string
  default     = "us-central1"
}

variable "router_asn" {
  description = "ASN for Cloud Router"
  type        = number
  default     = 64514
}

variable "nat_ip_allocate_option" {
  description = "How NAT IPs are allocated"
  type        = string
  default     = "AUTO_ONLY"
}

variable "nat_source_ranges" {
  description = "Source ranges for NAT"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

variable "enable_nat_logs" {
  description = "Enable Cloud NAT logging"
  type        = bool
  default     = true
}

variable "nat_log_filter" {
  description = "Cloud NAT log filter"
  type        = string
  default     = "ERRORS_ONLY"
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of ports per VM"
  type        = number
  default     = 64
}

variable "nat_max_ports_per_vm" {
  description = "Maximum number of ports per VM"
  type        = number
  default     = null
}

variable "nat_enable_endpoint_independent_mapping" {
  description = "Enable endpoint independent mapping"
  type        = bool
  default     = false
}

variable "enable_iap_ssh" {
  description = "Enable SSH access through IAP"
  type        = bool
  default     = true
}

variable "enable_http_https" {
  description = "Enable HTTP/HTTPS firewall rules"
  type        = bool
  default     = true
}

variable "enable_default_deny" {
  description = "Enable default deny ingress rule"
  type        = bool
  default     = false
}

variable "enable_private_service_access" {
  description = "Enable private service access for managed services"
  type        = bool
  default     = true
}

variable "private_service_prefix_length" {
  description = "Prefix length for private service access range"
  type        = number
  default     = 16
}
