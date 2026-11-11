output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host, for `aws ssm start-session`. Null when the bastion is not included."
  value       = one(aws_instance.bastion[*].id)
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host. Null when the bastion is not included."
  value       = one(aws_instance.bastion[*].public_ip)
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster. Null when EKS is not included."
  value       = one(aws_eks_cluster.this[*].name)
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS API. Null when EKS is not included."
  value       = one(aws_eks_cluster.this[*].endpoint)
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance. Null when RDS is not included."
  value       = one(aws_db_instance.this[*].endpoint)
}

output "rds_database_name" {
  description = "Name of the database. Null when RDS is not included."
  value       = one(aws_db_instance.this[*].db_name)
}

output "rds_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the database master password. Null when RDS is not included."
  value       = one(flatten(aws_db_instance.this[*].master_user_secret[*].secret_arn))
}
