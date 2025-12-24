# =============================================================================
# AWS VPC Module - Variables
# =============================================================================
# Input variables for the VPC module. No default values with Jinja2 templates.
# All environment-specific values should be passed from the root module.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the VPC and resources"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "Name must be between 1 and 64 characters."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "development", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, development, staging, prod, production."
  }
}

# -----------------------------------------------------------------------------
# Optional Variables - Networking
# -----------------------------------------------------------------------------
variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zones_count >= 1 && var.availability_zones_count <= 6
    error_message = "Availability zones count must be between 1 and 6."
  }
}

variable "subnet_newbits" {
  description = "Number of additional bits to add to the VPC CIDR for subnet calculation"
  type        = number
  default     = 4
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

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "Flow logs traffic type must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_logs_retention_days)
    error_message = "Flow logs retention must be a valid CloudWatch Logs retention period."
  }
}

# -----------------------------------------------------------------------------
# Optional Variables - Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
