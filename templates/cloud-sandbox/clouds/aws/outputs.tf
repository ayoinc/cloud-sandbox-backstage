output "vpc_id" {
  description = "ID of the VPC."
  value       = module.sandbox.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.sandbox.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.sandbox.private_subnet_ids
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host, for `aws ssm start-session`. Null when the bastion is not included."
  value       = module.sandbox.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host. Null when the bastion is not included."
  value       = module.sandbox.bastion_public_ip
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster. Null when EKS is not included."
  value       = module.sandbox.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS API. Null when EKS is not included."
  value       = module.sandbox.eks_cluster_endpoint
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance. Null when RDS is not included."
  value       = module.sandbox.rds_endpoint
}

output "rds_database_name" {
  description = "Name of the database. Null when RDS is not included."
  value       = module.sandbox.rds_database_name
}

output "rds_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the database master password. Null when RDS is not included."
  value       = module.sandbox.rds_master_user_secret_arn
}
