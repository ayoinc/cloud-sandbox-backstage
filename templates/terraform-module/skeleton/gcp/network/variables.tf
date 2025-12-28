# -----------------------------------------------------------------------------
# GCP Network Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project and Environment
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "uat", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, uat, prod, production."
  }
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_name" {
  description = "Base name for the VPC network"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.network_name)) && length(var.network_name) <= 63
    error_message = "Network name must start with a letter, end with a letter or number, contain only lowercase letters, numbers, and hyphens, and be at most 63 characters."
  }
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "GLOBAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be either REGIONAL or GLOBAL."
  }
}

variable "delete_default_routes" {
  description = "Delete default routes on VPC creation (set to true if using custom routes only)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Subnet Configuration
# -----------------------------------------------------------------------------

variable "subnet_cidrs" {
  description = "CIDR blocks for each subnet type"
  type = object({
    public   = string
    private  = string
    database = string
  })
  default = {
    public   = "10.0.1.0/24"
    private  = "10.0.2.0/24"
    database = "10.0.3.0/24"
  }

  validation {
    condition     = can(cidrhost(var.subnet_cidrs.public, 0)) && can(cidrhost(var.subnet_cidrs.private, 0)) && can(cidrhost(var.subnet_cidrs.database, 0))
    error_message = "All subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "enable_private_google_access" {
  description = "Enable Private Google Access for subnets (allows VMs without external IPs to reach Google APIs)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# GKE Secondary Ranges
# -----------------------------------------------------------------------------

variable "enable_gke_secondary_ranges" {
  description = "Enable secondary IP ranges for GKE pods and services on private subnet"
  type        = bool
  default     = true
}

variable "secondary_ranges" {
  description = "Secondary IP ranges for GKE pods and services"
  type = object({
    pods     = string
    services = string
  })
  default = {
    pods     = "10.1.0.0/16"
    services = "10.2.0.0/20"
  }

  validation {
    condition     = can(cidrhost(var.secondary_ranges.pods, 0)) && can(cidrhost(var.secondary_ranges.services, 0))
    error_message = "Secondary ranges must be valid IPv4 CIDR blocks."
  }
}

# -----------------------------------------------------------------------------
# Cloud Router and NAT Configuration
# -----------------------------------------------------------------------------

variable "enable_nat" {
  description = "Enable Cloud NAT for private and database subnets"
  type        = bool
  default     = true
}

variable "router_asn" {
  description = "BGP ASN for Cloud Router (private range: 64512-65534 or 4200000000-4294967294)"
  type        = number
  default     = 64514

  validation {
    condition     = (var.router_asn >= 64512 && var.router_asn <= 65534) || (var.router_asn >= 4200000000 && var.router_asn <= 4294967294)
    error_message = "Router ASN must be in the private range: 64512-65534 or 4200000000-4294967294."
  }
}

variable "router_advertised_ip_ranges" {
  description = "Additional IP ranges to advertise via BGP"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "nat_ip_allocate_option" {
  description = "How external IPs are allocated for Cloud NAT (AUTO_ONLY or MANUAL_ONLY)"
  type        = string
  default     = "AUTO_ONLY"

  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocate_option)
    error_message = "NAT IP allocate option must be AUTO_ONLY or MANUAL_ONLY."
  }
}

variable "nat_ip_count" {
  description = "Number of external IPs to allocate for NAT (only used when nat_ip_allocate_option is MANUAL_ONLY)"
  type        = number
  default     = 1

  validation {
    condition     = var.nat_ip_count >= 1 && var.nat_ip_count <= 10
    error_message = "NAT IP count must be between 1 and 10."
  }
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of ports allocated per VM for NAT"
  type        = number
  default     = 64

  validation {
    condition     = var.nat_min_ports_per_vm >= 64 && var.nat_min_ports_per_vm <= 65536
    error_message = "NAT min ports per VM must be between 64 and 65536."
  }
}

variable "nat_max_ports_per_vm" {
  description = "Maximum number of ports allocated per VM for NAT (when dynamic port allocation is enabled)"
  type        = number
  default     = 65536
}

variable "enable_dynamic_port_allocation" {
  description = "Enable dynamic port allocation for Cloud NAT"
  type        = bool
  default     = true
}

variable "enable_endpoint_independent_mapping" {
  description = "Enable endpoint-independent mapping for NAT"
  type        = bool
  default     = false
}

variable "nat_icmp_idle_timeout_sec" {
  description = "ICMP idle timeout in seconds"
  type        = number
  default     = 30
}

variable "nat_tcp_established_idle_timeout_sec" {
  description = "TCP established connection idle timeout in seconds"
  type        = number
  default     = 1200
}

variable "nat_tcp_transitory_idle_timeout_sec" {
  description = "TCP transitory connection idle timeout in seconds"
  type        = number
  default     = 30
}

variable "nat_udp_idle_timeout_sec" {
  description = "UDP idle timeout in seconds"
  type        = number
  default     = 30
}

variable "nat_log_filter" {
  description = "Filter for NAT logs (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
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

variable "ssh_source_ranges" {
  description = "Source CIDR ranges allowed to SSH (use IAP range 35.235.240.0/20 for secure access)"
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "http_source_ranges" {
  description = "Source CIDR ranges allowed for HTTP traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_source_ranges" {
  description = "Source CIDR ranges allowed for HTTPS traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_iap_access" {
  description = "Enable Identity-Aware Proxy firewall rule for secure SSH/RDP access"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Private Service Access
# -----------------------------------------------------------------------------

variable "enable_private_service_access" {
  description = "Enable Private Service Access for managed services (Cloud SQL, Memorystore, etc.)"
  type        = bool
  default     = true
}

variable "private_service_access_address" {
  description = "Starting IP address for Private Service Access range (leave null for auto-allocation)"
  type        = string
  default     = null
}

variable "private_service_access_prefix_length" {
  description = "Prefix length for Private Service Access IP range"
  type        = number
  default     = 16

  validation {
    condition     = var.private_service_access_prefix_length >= 8 && var.private_service_access_prefix_length <= 24
    error_message = "Private Service Access prefix length must be between 8 and 24."
  }
}

# -----------------------------------------------------------------------------
# Private DNS
# -----------------------------------------------------------------------------

variable "enable_private_dns" {
  description = "Enable private DNS zone for the VPC"
  type        = bool
  default     = false
}

variable "private_dns_domain" {
  description = "Domain name for private DNS zone (e.g., 'internal.example.com.')"
  type        = string
  default     = "internal.local."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*\\.$", var.private_dns_domain))
    error_message = "Private DNS domain must be a valid DNS name ending with a period."
  }
}

# -----------------------------------------------------------------------------
# Shared VPC
# -----------------------------------------------------------------------------

variable "enable_shared_vpc_host" {
  description = "Enable this project as a Shared VPC host project"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Tags / Labels
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[a-z][a-z0-9_-]*$", k)) && length(k) <= 63 && length(v) <= 63
    ])
    error_message = "Label keys must start with a lowercase letter, contain only lowercase letters, numbers, hyphens, and underscores, and be at most 63 characters."
  }
}
