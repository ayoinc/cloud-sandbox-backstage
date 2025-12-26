output "vpc_id" {
  description = "VPC ID"
  value       = module.infrastructure.aws_vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.infrastructure.aws_public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.infrastructure.aws_private_subnet_ids
}
