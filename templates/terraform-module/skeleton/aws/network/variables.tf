# -----------------------------------------------------------------------------
# AWS Network Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as the prefix of every resource name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9._-]*$", var.project_name))
    error_message = "project_name must start with a letter and contain only letters, digits, dots, underscores and hyphens."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,8}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC. Subnets are /(prefix+4) slices, so the prefix must be between /16 and /24"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && try(tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 24, false)
    error_message = "vpc_cidr must be a valid IPv4 CIDR block with a prefix length between /16 and /24."
  }
}

variable "availability_zones" {
  description = "Availability zones to place subnets in. Leave empty to use the first az_count zones available in the region"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) <= 5 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "availability_zones must contain at most 5 distinct zone names."
  }
}

variable "az_count" {
  description = "Number of availability zones to use when availability_zones is empty"
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 5 && floor(var.az_count) == var.az_count
    error_message = "az_count must be a whole number between 1 and 5."
  }
}

variable "map_public_ip_on_launch" {
  description = "Assign a public IPv4 address to instances launched in the public subnets"
  type        = bool
  default     = false
}

variable "enable_nat" {
  description = "Create NAT gateways so the private and database subnets can reach the internet"
  type        = bool
  default     = true
}

variable "single_nat" {
  description = "Use one shared NAT gateway instead of one per availability zone (cheaper, not highly available)"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to a CloudWatch log group"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention of the flow log group in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_logs_retention_days)
    error_message = "flow_logs_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the flow log group. The key policy must allow the CloudWatch Logs service. Null uses the CloudWatch Logs service key"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
