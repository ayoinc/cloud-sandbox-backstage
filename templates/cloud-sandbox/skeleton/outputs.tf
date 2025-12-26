# =============================================================================
# Cloud Sandbox Outputs
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.sandbox.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.sandbox.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.sandbox.private_subnet_ids
}

output "bastion_public_ip" {
  description = "Public IP of bastion host (if enabled)"
  value       = module.sandbox.bastion_public_ip
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint (if enabled)"
  value       = module.sandbox.eks_cluster_endpoint
}

output "rds_endpoint" {
  description = "RDS endpoint (if enabled)"
  value       = module.sandbox.rds_endpoint
}
