################################################################################
# General
################################################################################

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# ECS Cluster
################################################################################

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "capacity_providers" {
  description = "List of capacity providers to associate with the cluster"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

################################################################################
# Task Definition
################################################################################

variable "task_family" {
  description = "Family name for the task definition"
  type        = string
}

variable "cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MiB) for the task"
  type        = number
  default     = 512
}

variable "network_mode" {
  description = "Network mode for the task (awsvpc, bridge, host, none)"
  type        = string
  default     = "awsvpc"
}

variable "requires_compatibilities" {
  description = "Launch type compatibility requirements (FARGATE, EC2)"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "execution_role_arn" {
  description = "ARN of the task execution IAM role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task IAM role for container permissions"
  type        = string
  default     = null
}

variable "container_definitions" {
  description = "JSON encoded container definitions for the task"
  type        = string
}

################################################################################
# ECS Service
################################################################################

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "desired_count" {
  description = "Desired number of task instances"
  type        = number
  default     = 1
}

variable "subnets" {
  description = "List of subnet IDs for the service"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs for the service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to the task ENI"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the target group for load balancer integration"
  type        = string
  default     = null
}

variable "container_name" {
  description = "Name of the container to associate with the load balancer"
  type        = string
  default     = null
}

variable "container_port" {
  description = "Port on the container to associate with the load balancer"
  type        = number
  default     = 80
}

variable "health_check_grace_period_seconds" {
  description = "Grace period for health checks when using load balancer"
  type        = number
  default     = 60
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 50
}

variable "deployment_maximum_percent" {
  description = "Maximum percent of tasks during deployment"
  type        = number
  default     = 200
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

################################################################################
# Service Discovery
################################################################################

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map service discovery"
  type        = bool
  default     = false
}

variable "service_discovery_vpc_id" {
  description = "VPC ID for the service discovery namespace"
  type        = string
  default     = null
}
