# -----------------------------------------------------------------------------
# Project
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Project name, used as the prefix of every resource name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "The project name may contain lowercase letters, numbers and hyphens only."
  }
}

variable "component_name" {
  description = "Name of this infrastructure component in the software catalog"
  type        = string
}

variable "owner" {
  description = "Team that owns the infrastructure"
  type        = string
}

variable "environment" {
  description = "Environment this stack is deployed to"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "dr"], var.environment)
    error_message = "The environment must be dev, staging, prod or dr."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags added to every resource"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Resource categories
# -----------------------------------------------------------------------------
variable "enable_networking" {
  description = "Create the VPC, subnets, gateways and route tables"
  type        = bool
  default     = true
}

variable "enable_compute" {
  description = "Create the EC2 launch template and Auto Scaling group"
  type        = bool
  default     = true
}

variable "enable_containers" {
  description = "Create the EKS cluster, node group and ECR repository"
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Create the S3 bucket and, with enable_efs, the EFS file system"
  type        = bool
  default     = true
}

variable "enable_database" {
  description = "Create the RDS instance and, when enabled, DynamoDB and ElastiCache"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Enable GuardDuty, IAM Access Analyzer and EBS encryption by default"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Create the alarm topic, application log group, alarms and dashboard"
  type        = bool
  default     = true
}

variable "enable_analytics" {
  description = "Create the Kinesis data stream and Glue catalog database"
  type        = bool
  default     = false
}

variable "enable_integration" {
  description = "Create the SQS queues, SNS topic and EventBridge bus"
  type        = bool
  default     = false
}

variable "enable_ai_ml" {
  description = "Create the SageMaker execution role and model package group"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "The VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "subnet_configurations" {
  description = "Subnets to create. Public subnets route to the internet gateway, private subnets to the NAT gateway, isolated subnets have no route out of the VPC"
  type = list(object({
    name = string
    cidr = string
    type = string
  }))
  default = []

  validation {
    condition     = alltrue([for subnet in var.subnet_configurations : contains(["public", "private", "isolated"], subnet.type)])
    error_message = "The subnet type must be public, private or isolated."
  }

  validation {
    condition     = length(distinct([for subnet in var.subnet_configurations : subnet.name])) == length(var.subnet_configurations)
    error_message = "Subnet names must be unique."
  }
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so private subnets can reach the internet"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Attach a virtual private gateway to the VPC"
  type        = bool
  default     = false
}

variable "enable_transit_gateway" {
  description = "Create a transit gateway and attach the VPC to it"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Days the VPC flow logs are kept"
  type        = number
  default     = 365
}

variable "existing_vpc_id" {
  description = "VPC used by the other categories when enable_networking is false"
  type        = string
  default     = ""
}

variable "existing_private_subnet_ids" {
  description = "Private subnets used by the other categories when enable_networking is false"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Compute
# -----------------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type of the Auto Scaling group"
  type        = string
  default     = "t3.medium"
}

variable "ebs_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 50
}

variable "asg_min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Number of instances the group starts with"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Containers
# -----------------------------------------------------------------------------
variable "eks_version" {
  description = "Kubernetes version of the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "eks_node_group_instance_types" {
  description = "Instance types of the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_nodes" {
  description = "Number of nodes the group starts with"
  type        = number
  default     = 3
}

variable "eks_min_nodes" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "eks_max_nodes" {
  description = "Maximum number of nodes"
  type        = number
  default     = 10
}

variable "eks_endpoint_public_access" {
  description = "Expose the Kubernetes API server on the internet. Needs eks_public_access_cidrs"
  type        = bool
  default     = false
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API server endpoint"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------
variable "s3_bucket_encryption" {
  description = "Encrypt the bucket with the KMS key of this stack instead of the S3 managed key"
  type        = bool
  default     = true
}

variable "s3_versioning" {
  description = "Keep previous versions of objects"
  type        = bool
  default     = true
}

variable "enable_efs" {
  description = "Create an EFS file system with a mount target in every private subnet"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------
variable "rds_instance_class" {
  description = "Instance class of the PostgreSQL database"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Storage of the database in GB"
  type        = number
  default     = 20
}

variable "rds_backup_retention" {
  description = "Days automated backups are kept"
  type        = number
  default     = 7
}

variable "rds_engine_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
}

variable "rds_multi_az" {
  description = "Run a standby instance in a second availability zone"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protect the database and the DynamoDB table against deletion"
  type        = bool
  default     = true
}

variable "enable_dynamodb" {
  description = "Create a DynamoDB table"
  type        = bool
  default     = false
}

variable "enable_elasticache" {
  description = "Create an ElastiCache Redis replication group"
  type        = bool
  default     = false
}

variable "elasticache_node_type" {
  description = "Node type of the Redis replication group"
  type        = string
  default     = "cache.t4g.micro"
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------
variable "log_retention_days" {
  description = "Days application logs are kept"
  type        = number
  default     = 365
}

variable "alarm_email" {
  description = "Email address subscribed to the alarm topic. No subscription when empty"
  type        = string
  default     = ""
}
