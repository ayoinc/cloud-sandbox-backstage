output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = module.alb.lb_dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the application load balancer"
  value       = module.alb.lb_zone_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster (ecs-fargate and ecs-ec2)"
  value       = one(module.ecs[*].cluster_name)
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group (ecs-ec2 and ec2-asg)"
  value       = one(module.instances[*].autoscaling_group_name)
}

output "database_endpoint" {
  description = "Endpoint of the database"
  value       = module.rds.db_instance_endpoint
}

output "database_port" {
  description = "Port of the database"
  value       = module.rds.db_instance_port
}

output "database_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret that holds the database master password"
  value       = module.rds.master_user_secret_arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF web ACL, when enable_waf is true"
  value       = one(module.waf[*].web_acl_arn)
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution, when enable_cloudfront is true"
  value       = one(module.cloudfront[*].distribution_domain_name)
}
