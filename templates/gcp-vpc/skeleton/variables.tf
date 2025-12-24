# =============================================================================
# GCP VPC - Root Variables
# =============================================================================
# These variables are passed to the VPC module.
# Values are provided via environment-specific tfvars files.
# NO JINJA2 DEFAULTS - All values come from tfvars files.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the VPC (used in resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for the VPC resources"
  type        = string
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
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"
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
}

# -----------------------------------------------------------------------------
# Subnet CIDR Blocks
# -----------------------------------------------------------------------------

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "database_subnet_cidr" {
  description = "CIDR block for the database subnet"
  type        = string
}

variable "gke_subnet_cidr" {
  description = "CIDR block for the GKE subnet"
  type        = string
}

variable "gke_pods_cidr" {
  description = "Secondary CIDR block for GKE pods"
  type        = string
  default     = "10.100.0.0/16"
}

variable "gke_services_cidr" {
  description = "Secondary CIDR block for GKE services"
  type        = string
  default     = "10.101.0.0/20"
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

# -----------------------------------------------------------------------------
# Cloud Router Configuration
# -----------------------------------------------------------------------------

variable "router_asn" {
  description = "BGP ASN for the Cloud Router"
  type        = number
  default     = 64514
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
}

variable "nat_source_subnetwork_ip_ranges" {
  description = "Which subnetworks to NAT"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of ports allocated per VM"
  type        = number
  default     = 64
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
}
