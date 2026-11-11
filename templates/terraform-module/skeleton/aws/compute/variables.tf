# -----------------------------------------------------------------------------
# AWS Compute Module - Variables
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

variable "vpc_id" {
  description = "ID of the VPC the instances are placed in"
  type        = string

  validation {
    condition     = var.vpc_id != null
    error_message = "vpc_id is required. Enable the network module or pass an existing VPC."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs for the instances"
  type        = list(string)

  validation {
    condition     = var.subnet_ids != null && length(coalesce(var.subnet_ids, [])) >= 1
    error_message = "subnet_ids must contain at least one subnet ID."
  }
}

variable "instance_type" {
  description = "EC2 instance type (x86_64 when the default AMI is used)"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the instances. Null or empty selects the latest Amazon Linux 2023 x86_64 AMI"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 0 && var.min_size <= var.max_size
    error_message = "min_size must be between 0 and max_size."
  }
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Initial number of instances. Later changes made by scaling policies are kept"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= var.min_size && var.desired_capacity <= var.max_size
    error_message = "desired_capacity must be between min_size and max_size."
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GB."
  }
}

variable "ssh_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to SSH to the instances. Empty (default) means no SSH ingress; use Session Manager instead"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "ssh_allowed_cidrs must be valid IPv4 CIDR blocks and must not include 0.0.0.0/0."
  }
}

variable "app_ports" {
  description = "TCP ports the application listens on"
  type        = list(number)
  default     = [80, 443]
}

variable "app_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach app_ports (for example the VPC CIDR)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.app_allowed_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "app_allowed_cidrs must be valid IPv4 CIDR blocks and must not include 0.0.0.0/0. Publish the application through a load balancer instead."
  }
}

variable "app_allowed_security_group_ids" {
  description = "Security group IDs (for example a load balancer's) allowed to reach app_ports"
  type        = list(string)
  default     = []
}

variable "target_group_arns" {
  description = "Load balancer target group ARNs the instances register with"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "Auto Scaling health check type (EC2 or ELB). ELB requires target_group_arns"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Seconds after launch before health checks count"
  type        = number
  default     = 300
}

variable "enable_detailed_monitoring" {
  description = "Enable 1-minute EC2 detailed monitoring"
  type        = bool
  default     = true
}

variable "scale_up_threshold" {
  description = "Average CPU percentage above which one instance is added"
  type        = number
  default     = 80
}

variable "scale_down_threshold" {
  description = "Average CPU percentage below which one instance is removed"
  type        = number
  default     = 20

  validation {
    condition     = var.scale_down_threshold < var.scale_up_threshold
    error_message = "scale_down_threshold must be lower than scale_up_threshold."
  }
}

variable "log_retention_days" {
  description = "Retention in days of the instance log groups"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
