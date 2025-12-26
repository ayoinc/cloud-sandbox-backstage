# =============================================================================
# Cloud Sandbox Module - Outputs
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = var.include_bastion ? module.bastion[0].public_ip : null
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.include_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = var.include_eks ? module.eks[0].cluster_name : null
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = var.include_rds ? module.rds[0].db_instance_endpoint : null
}

output "rds_database_name" {
  description = "RDS database name"
  value       = var.include_rds ? module.rds[0].db_instance_name : null
}
