variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The ID of the project where the Cloud NAT will be created"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The region where the Cloud NAT will be created"
  type        = string
}

variable "router_name" {
  description = "The name of the Cloud Router to associate with the NAT"
  type        = string
}

variable "nat_name" {
  description = "The name of the Cloud NAT"
  type        = string
}

variable "nat_ip_allocate_option" {
  description = "How external IPs should be allocated for this NAT. Valid values are AUTO_ONLY or MANUAL_ONLY"
  type        = string
  default     = "AUTO_ONLY"

  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocate_option)
    error_message = "nat_ip_allocate_option must be either AUTO_ONLY or MANUAL_ONLY."
  }
}

variable "nat_ips" {
  description = "List of self_links of external IPs to use for NAT. Required when nat_ip_allocate_option is MANUAL_ONLY"
  type        = list(string)
  default     = []
}

variable "source_subnetwork_ip_ranges_to_nat" {
  description = "How NAT should be configured per Subnetwork. Valid values are ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES, or LIST_OF_SUBNETWORKS"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  validation {
    condition     = contains(["ALL_SUBNETWORKS_ALL_IP_RANGES", "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES", "LIST_OF_SUBNETWORKS"], var.source_subnetwork_ip_ranges_to_nat)
    error_message = "source_subnetwork_ip_ranges_to_nat must be one of ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES, or LIST_OF_SUBNETWORKS."
  }
}

variable "subnetworks" {
  description = "List of subnetworks to configure for NAT. Required when source_subnetwork_ip_ranges_to_nat is LIST_OF_SUBNETWORKS"
  type = list(object({
    name                     = string
    source_ip_ranges_to_nat  = list(string)
    secondary_ip_range_names = optional(list(string))
  }))
  default = []
}

variable "min_ports_per_vm" {
  description = "Minimum number of ports allocated to a VM from this NAT"
  type        = number
  default     = 64
}

variable "max_ports_per_vm" {
  description = "Maximum number of ports allocated to a VM from this NAT. Required when enable_dynamic_port_allocation is true"
  type        = number
  default     = null
}

variable "enable_dynamic_port_allocation" {
  description = "Enable Dynamic Port Allocation. If enabled, min_ports_per_vm and max_ports_per_vm must be set"
  type        = bool
  default     = false
}

variable "enable_endpoint_independent_mapping" {
  description = "Enable endpoint independent mapping. Must be disabled when dynamic port allocation is enabled"
  type        = bool
  default     = false
}

variable "udp_idle_timeout_sec" {
  description = "Timeout in seconds for UDP connections"
  type        = number
  default     = 30
}

variable "tcp_established_idle_timeout_sec" {
  description = "Timeout in seconds for TCP established connections"
  type        = number
  default     = 1200
}

variable "tcp_transitory_idle_timeout_sec" {
  description = "Timeout in seconds for TCP transitory connections"
  type        = number
  default     = 30
}

variable "tcp_time_wait_timeout_sec" {
  description = "Timeout in seconds for TCP connections in TIME_WAIT state"
  type        = number
  default     = 120
}

variable "icmp_idle_timeout_sec" {
  description = "Timeout in seconds for ICMP connections"
  type        = number
  default     = 30
}

variable "log_config_enable" {
  description = "Enable logging for the NAT"
  type        = bool
  default     = false
}

variable "log_config_filter" {
  description = "Filter for logs. Valid values are ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.log_config_filter)
    error_message = "log_config_filter must be one of ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}
