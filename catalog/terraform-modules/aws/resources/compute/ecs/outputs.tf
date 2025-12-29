################################################################################
# ECS Cluster
################################################################################

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

################################################################################
# Task Definition
################################################################################

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.this.revision
}

################################################################################
# ECS Service
################################################################################

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.this.id
}

################################################################################
# CloudWatch
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.arn
}

################################################################################
# Service Discovery
################################################################################

output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = try(aws_service_discovery_private_dns_namespace.this[0].id, null)
}

output "service_discovery_namespace_arn" {
  description = "ARN of the service discovery namespace"
  value       = try(aws_service_discovery_private_dns_namespace.this[0].arn, null)
}

output "service_discovery_service_arn" {
  description = "ARN of the service discovery service"
  value       = try(aws_service_discovery_service.this[0].arn, null)
}
