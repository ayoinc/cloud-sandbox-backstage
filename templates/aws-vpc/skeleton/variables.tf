# =============================================================================
# AWS VPC - Root Variables
# =============================================================================
# Variables for the root module. These are passed to the child VPC module.
# Values come from environments/*.tfvars files.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the VPC and resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# Optional Variables - Networking
# -----------------------------------------------------------------------------
variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Optional Variables - NAT Gateway
# -----------------------------------------------------------------------------
variable "enable_nat_gateway" {
  description = "Enable NAT gateways for private subnets"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Optional Variables - Flow Logs
# -----------------------------------------------------------------------------
variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture (ACCEPT, REJECT, or ALL)"
  type        = string
  default     = "ALL"
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 14
}

# -----------------------------------------------------------------------------
# Optional Variables - Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
