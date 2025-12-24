# =============================================================================
# GCP VPC Module - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the VPC (used in resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Name must be 3-63 characters, lowercase alphanumeric and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "development", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, development, production."
  }
}

variable "region" {
  description = "GCP region for the VPC resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region (e.g., us-central1, europe-west1)."
  }
}

# -----------------------------------------------------------------------------
# Optional Metadata
# -----------------------------------------------------------------------------

variable "description" {
  description = "Description of the VPC purpose"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the VPC resources"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------

variable "address_space" {
  description = "Primary CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.address_space, 0))
    error_message = "Address space must be a valid CIDR block."
  }
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be REGIONAL or GLOBAL."
  }
}

variable "delete_default_routes" {
  description = "Delete default routes on VPC creation"
  type        = bool
  default     = false
}

variable "mtu" {
  description = "Maximum Transmission Unit (MTU) for the network"
  type        = number
  default     = 1460

  validation {
    condition     = var.mtu >= 1300 && var.mtu <= 8896
    error_message = "MTU must be between 1300 and 8896."
  }
}

# -----------------------------------------------------------------------------
# Subnet CIDR Blocks
# -----------------------------------------------------------------------------

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid CIDR block."
  }
}

variable "database_subnet_cidr" {
  description = "CIDR block for the database subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.database_subnet_cidr, 0))
    error_message = "Database subnet CIDR must be a valid CIDR block."
  }
}

variable "gke_subnet_cidr" {
  description = "CIDR block for the GKE subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.gke_subnet_cidr, 0))
    error_message = "GKE subnet CIDR must be a valid CIDR block."
  }
}

variable "gke_pods_cidr" {
  description = "Secondary CIDR block for GKE pods"
  type        = string
  default     = "10.100.0.0/16"

  validation {
    condition     = can(cidrhost(var.gke_pods_cidr, 0))
    error_message = "GKE pods CIDR must be a valid CIDR block."
  }
}

variable "gke_services_cidr" {
  description = "Secondary CIDR block for GKE services"
  type        = string
  default     = "10.101.0.0/20"

  validation {
    condition     = can(cidrhost(var.gke_services_cidr, 0))
    error_message = "GKE services CIDR must be a valid CIDR block."
  }
}

# -----------------------------------------------------------------------------
# Flow Logs Configuration
# -----------------------------------------------------------------------------

variable "enable_flow_logs" {
  description = "Enable VPC flow logs for subnets"
  type        = bool
  default     = true
}

variable "flow_logs_interval" {
  description = "Aggregation interval for flow logs"
  type        = string
  default     = "INTERVAL_5_SEC"

  validation {
    condition = contains([
      "INTERVAL_5_SEC", "INTERVAL_30_SEC", "INTERVAL_1_MIN",
      "INTERVAL_5_MIN", "INTERVAL_10_MIN", "INTERVAL_15_MIN"
    ], var.flow_logs_interval)
    error_message = "Flow logs interval must be a valid aggregation interval."
  }
}

variable "flow_logs_sampling" {
  description = "Sampling rate for flow logs (0.0 to 1.0)"
  type        = number
  default     = 0.5

  validation {
    condition     = var.flow_logs_sampling >= 0 && var.flow_logs_sampling <= 1
    error_message = "Flow logs sampling must be between 0 and 1."
  }
}

variable "flow_logs_metadata" {
  description = "Metadata to include in flow logs"
  type        = string
  default     = "INCLUDE_ALL_METADATA"

  validation {
    condition     = contains(["EXCLUDE_ALL_METADATA", "INCLUDE_ALL_METADATA", "CUSTOM_METADATA"], var.flow_logs_metadata)
    error_message = "Flow logs metadata must be EXCLUDE_ALL_METADATA, INCLUDE_ALL_METADATA, or CUSTOM_METADATA."
  }
}

# -----------------------------------------------------------------------------
# Cloud Router Configuration
# -----------------------------------------------------------------------------

variable "router_asn" {
  description = "BGP ASN for the Cloud Router"
  type        = number
  default     = 64514

  validation {
    condition     = var.router_asn >= 64512 && var.router_asn <= 65534
    error_message = "Router ASN must be a valid private ASN (64512-65534)."
  }
}

# -----------------------------------------------------------------------------
# Cloud NAT Configuration
# -----------------------------------------------------------------------------

variable "enable_nat" {
  description = "Enable Cloud NAT for outbound internet access"
  type        = bool
  default     = true
}

variable "nat_ip_allocate_option" {
  description = "How NAT IPs should be allocated"
  type        = string
  default     = "AUTO_ONLY"

  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocate_option)
    error_message = "NAT IP allocate option must be AUTO_ONLY or MANUAL_ONLY."
  }
}

variable "nat_source_subnetwork_ip_ranges" {
  description = "Which subnetworks to NAT"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  validation {
    condition = contains([
      "ALL_SUBNETWORKS_ALL_IP_RANGES",
      "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES",
      "LIST_OF_SUBNETWORKS"
    ], var.nat_source_subnetwork_ip_ranges)
    error_message = "NAT source subnetwork IP ranges must be a valid option."
  }
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of ports allocated per VM"
  type        = number
  default     = 64

  validation {
    condition     = var.nat_min_ports_per_vm >= 64 && var.nat_min_ports_per_vm <= 65536
    error_message = "NAT min ports per VM must be between 64 and 65536."
  }
}

variable "nat_max_ports_per_vm" {
  description = "Maximum number of ports allocated per VM (0 for no limit)"
  type        = number
  default     = 0
}

variable "nat_enable_endpoint_independent_mapping" {
  description = "Enable endpoint independent mapping"
  type        = bool
  default     = false
}

variable "nat_tcp_established_idle_timeout" {
  description = "TCP established connection idle timeout (seconds)"
  type        = number
  default     = 1200
}

variable "nat_tcp_transitory_idle_timeout" {
  description = "TCP transitory connection idle timeout (seconds)"
  type        = number
  default     = 30
}

variable "nat_udp_idle_timeout" {
  description = "UDP idle timeout (seconds)"
  type        = number
  default     = 30
}

variable "nat_log_enable" {
  description = "Enable Cloud NAT logging"
  type        = bool
  default     = true
}

variable "nat_log_filter" {
  description = "Cloud NAT log filter"
  type        = string
  default     = "ERRORS_ONLY"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_filter)
    error_message = "NAT log filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}

# -----------------------------------------------------------------------------
# Firewall Configuration
# -----------------------------------------------------------------------------

variable "enable_http_firewall" {
  description = "Enable HTTP/HTTPS firewall rule for tagged instances"
  type        = bool
  default     = true
}

variable "enable_deny_all_firewall" {
  description = "Enable deny-all ingress firewall rule (catch-all)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Private Service Access Configuration
# -----------------------------------------------------------------------------

variable "enable_private_service_access" {
  description = "Enable Private Service Access for Cloud SQL, Memorystore, etc."
  type        = bool
  default     = false
}

variable "private_service_access_prefix_length" {
  description = "Prefix length for Private Service Access CIDR block"
  type        = number
  default     = 16

  validation {
    condition     = var.private_service_access_prefix_length >= 8 && var.private_service_access_prefix_length <= 24
    error_message = "Private Service Access prefix length must be between 8 and 24."
  }
}
