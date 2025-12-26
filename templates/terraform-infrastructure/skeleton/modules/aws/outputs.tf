# AWS Module Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = var.enable_networking ? module.vpc.vpc_id : null
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.enable_networking ? module.vpc.vpc_cidr_block : null
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = var.enable_networking ? module.vpc.private_subnets : []
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = var.enable_networking ? module.vpc.public_subnets : []
}

# EKS Outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.enable_kubernetes ? module.eks.cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = var.enable_kubernetes ? module.eks.cluster_endpoint : null
  sensitive   = true
}

output "eks_cluster_version" {
  description = "Kubernetes version"
  value       = var.enable_kubernetes ? module.eks.cluster_version : null
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = var.enable_kubernetes ? module.eks.cluster_arn : null
}

output "eks_node_group_arn" {
  description = "ARN of the EKS node group"
  value       = var.enable_kubernetes ? module.eks.eks_managed_node_groups["default"].node_group_arn : null
}

# Storage Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = var.enable_storage ? aws_s3_bucket.main[0].id : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = var.enable_storage ? aws_s3_bucket.main[0].arn : null
}

# Database Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.enable_database ? module.rds.db_instance_endpoint : null
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.enable_database ? module.rds.db_instance_port : null
}

# Security Outputs
output "kms_key_id" {
  description = "KMS key ID"
  value       = var.enable_kms ? aws_kms_key.main[0].key_id : null
}

output "secrets_manager_arn" {
  description = "Secrets Manager ARN"
  value       = var.enable_secrets_manager ? aws_secretsmanager_secret.main[0].arn : null
}

# Networking Outputs
output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = var.enable_kubernetes ? "pending" : null
}
