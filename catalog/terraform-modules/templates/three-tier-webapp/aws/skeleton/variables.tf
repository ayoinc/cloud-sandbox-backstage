# Values chosen when this repository was created are in terraform.tfvars.

variable "project_name" {
  description = "Name of the project, used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment this stack belongs to"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging or production."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

# --- Application tier ---------------------------------------------------------

variable "compute_type" {
  description = "How the application runs: ecs-fargate, ecs-ec2 or ec2-asg"
  type        = string

  validation {
    condition     = contains(["ecs-fargate", "ecs-ec2", "ec2-asg"], var.compute_type)
    error_message = "compute_type must be ecs-fargate, ecs-ec2 or ec2-asg."
  }
}

variable "instance_type" {
  description = "EC2 instance type (ecs-ec2 and ec2-asg)"
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of tasks or instances"
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of tasks or instances. A value below min_capacity counts as min_capacity."
  type        = number
}

variable "cpu_target" {
  description = "Average CPU utilisation, in percent, that auto scaling keeps the application at"
  type        = number
  default     = 60
}

variable "container_image" {
  description = "Container image of the application (ecs-fargate and ecs-ec2)"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "container_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path the load balancer requests to check the application"
  type        = string
  default     = "/"
}

variable "task_cpu" {
  description = "CPU units of the ECS task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory of the ECS task in MiB"
  type        = number
  default     = 512
}

variable "ami_id" {
  description = "AMI for the EC2 instances. Defaults to the latest Amazon Linux 2023 image (ECS-optimised for ecs-ec2)."
  type        = string
  default     = null
}

# --- Data tier ----------------------------------------------------------------

variable "database_engine" {
  description = "Database engine: postgres, mysql or mariadb"
  type        = string

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.database_engine)
    error_message = "database_engine must be postgres, mysql or mariadb."
  }
}

variable "database_engine_version" {
  description = "Engine version. Defaults to a current major version of the chosen engine."
  type        = string
  default     = null
}

variable "database_parameter_group_family" {
  description = "Parameter group family. Set it together with database_engine_version."
  type        = string
  default     = null
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "multi_az" {
  description = "Keep a standby database instance in a second availability zone"
  type        = bool
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "app"
}

variable "database_username" {
  description = "Master username of the database"
  type        = string
  default     = "dbadmin"
}

variable "database_allocated_storage" {
  description = "Allocated database storage in GB"
  type        = number
  default     = 20
}

variable "database_max_allocated_storage" {
  description = "Upper limit for storage autoscaling in GB"
  type        = number
  default     = 100
}

# --- Edge ---------------------------------------------------------------------

variable "certificate_arn" {
  description = "ACM certificate for the HTTPS listener. A self-signed certificate is used while this is null."
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Attach an AWS WAF web ACL to the load balancer"
  type        = bool
}

variable "waf_rate_limit" {
  description = "Requests per five minutes from one address before WAF blocks it"
  type        = number
  default     = 2000
}

variable "enable_cloudfront" {
  description = "Put a CloudFront distribution in front of the load balancer"
  type        = bool
}

variable "origin_domain_name" {
  description = "DNS name of the load balancer that certificate_arn covers. CloudFront uses it as its origin."
  type        = string
  default     = null
}

variable "cloudfront_aliases" {
  description = "Alternate domain names of the CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate in us-east-1 for cloudfront_aliases"
  type        = string
  default     = null
}
