variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "${{ values.projectName }}"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "${{ values.environment }}"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "${{ values.region }}"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "${{ values.vpcCidr }}"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "${{ values.instanceType }}"
}

variable "min_capacity" {
  description = "Minimum number of instances"
  type        = number
  default     = ${{ values.minCapacity }}
}

variable "max_capacity" {
  description = "Maximum number of instances"
  type        = number
  default     = ${{ values.maxCapacity }}
}

variable "task_cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 512
}

variable "container_image" {
  description = "Docker image for the application"
  type        = string
  default     = "nginx:latest"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "database_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "${{ values.databaseEngine == 'postgres' and '15' or '8.0' }}"
}

variable "database_allocated_storage" {
  description = "Allocated storage for database in GB"
  type        = number
  default     = 20
}

variable "database_max_allocated_storage" {
  description = "Maximum allocated storage for database in GB"
  type        = number
  default     = 100
}

variable "database_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "cloudfront_aliases" {
  description = "CloudFront domain aliases"
  type        = list(string)
  default     = []
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (must be in us-east-1)"
  type        = string
  default     = ""
}
