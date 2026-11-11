variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.project_name))
    error_message = "project_name must start with a lowercase letter and contain only lowercase letters, digits and hyphens (max 63 characters)."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,7}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits and start with a letter."
  }
}

variable "project_id" {
  description = "ID of the Google Cloud project that owns the resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID (6-30 lowercase letters, digits or hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region for regional resources."
  type        = string
}

variable "labels" {
  description = "Labels applied to every resource that supports them."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "network_cidr" {
  description = "IPv4 range of the VPC. The private, public and database subnets are carved from it."
  type        = string
  default     = "10.2.0.0/16"

  validation {
    condition     = can(cidrhost(var.network_cidr, 0)) && can(regex("^[0-9.]+/[0-9]+$", var.network_cidr))
    error_message = "network_cidr must be a valid IPv4 CIDR block such as 10.2.0.0/16."
  }
}

variable "subnet_newbits" {
  description = "Bits added to the network_cidr prefix to size each subnet (4 turns a /16 into /20 subnets)."
  type        = number
  default     = 4

  validation {
    condition     = var.subnet_newbits >= 2 && var.subnet_newbits <= 12
    error_message = "subnet_newbits must be between 2 and 12."
  }
}

variable "routing_mode" {
  description = "Dynamic routing mode of the VPC: REGIONAL or GLOBAL."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "enable_flow_logs" {
  description = "Record VPC flow logs for every subnet."
  type        = bool
  default     = true
}

variable "flow_log_sampling" {
  description = "Fraction of flows recorded when flow logs are enabled (0 to 1)."
  type        = number
  default     = 0.5

  validation {
    condition     = var.flow_log_sampling > 0 && var.flow_log_sampling <= 1
    error_message = "flow_log_sampling must be greater than 0 and at most 1."
  }
}

variable "enable_gke_secondary_ranges" {
  description = "Add secondary ranges for GKE pods and services to the private subnet."
  type        = bool
  default     = true
}

variable "gke_pods_cidr" {
  description = "Secondary range for GKE pods. Must not overlap network_cidr."
  type        = string
  default     = "100.64.0.0/14"

  validation {
    condition     = can(cidrhost(var.gke_pods_cidr, 0))
    error_message = "gke_pods_cidr must be a valid IPv4 CIDR block."
  }
}

variable "gke_services_cidr" {
  description = "Secondary range for GKE services. Must not overlap network_cidr."
  type        = string
  default     = "100.68.0.0/20"

  validation {
    condition     = can(cidrhost(var.gke_services_cidr, 0))
    error_message = "gke_services_cidr must be a valid IPv4 CIDR block."
  }
}

variable "enable_nat" {
  description = "Create a Cloud Router and Cloud NAT so the private and database subnets can reach the internet."
  type        = bool
  default     = true
}

variable "nat_ip_count" {
  description = "Number of static external addresses reserved for Cloud NAT. 0 lets Google allocate addresses automatically."
  type        = number
  default     = 0

  validation {
    condition     = var.nat_ip_count >= 0 && var.nat_ip_count <= 8 && floor(var.nat_ip_count) == var.nat_ip_count
    error_message = "nat_ip_count must be a whole number between 0 and 8."
  }
}

variable "enable_iap_ssh" {
  description = "Allow SSH from Identity-Aware Proxy to instances tagged allow-iap-ssh."
  type        = bool
  default     = true
}

variable "web_source_ranges" {
  description = "Source ranges allowed to reach ports 80 and 443 on instances tagged web. Empty creates no rule."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for r in var.web_source_ranges : can(cidrhost(r, 0))])
    error_message = "Every entry in web_source_ranges must be a valid CIDR block."
  }
}

variable "enable_private_service_access" {
  description = "Reserve a range and peer the VPC with Google managed services (required for private Cloud SQL and Memorystore)."
  type        = bool
  default     = true
}

variable "private_service_access_prefix_length" {
  description = "Prefix length of the range reserved for Google managed services."
  type        = number
  default     = 20

  validation {
    condition     = var.private_service_access_prefix_length >= 16 && var.private_service_access_prefix_length <= 24
    error_message = "private_service_access_prefix_length must be between 16 and 24."
  }
}

variable "enable_private_dns" {
  description = "Create a private Cloud DNS zone visible only inside the VPC."
  type        = bool
  default     = false
}

variable "private_dns_domain" {
  description = "DNS name of the private zone. Must end with a dot."
  type        = string
  default     = "internal.example."

  validation {
    condition     = can(regex("^([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+$", var.private_dns_domain))
    error_message = "private_dns_domain must be a fully qualified domain name ending with a dot, such as internal.example."
  }
}

variable "enable_shared_vpc_host" {
  description = "Turn the project into a Shared VPC host project. Requires the Shared VPC Admin role on the organization or folder."
  type        = bool
  default     = false
}
