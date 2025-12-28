# -----------------------------------------------------------------------------
# AWS Compute Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID (leave empty for latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "target_group_arns" {
  description = "Target group ARNs for ALB"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "scale_up_threshold" {
  description = "CPU threshold for scaling up"
  type        = number
  default     = 80
}

variable "scale_down_threshold" {
  description = "CPU threshold for scaling down"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
