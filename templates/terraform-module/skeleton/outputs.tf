# Common outputs
output "name" {
  description = "The name prefix used for resources"
  value       = local.name_prefix
}

output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "tags" {
  description = "Common tags applied to resources"
  value       = local.common_tags
}

{%- if values.resource_type == 'compute' %}
{%- if values.provider == 'aws' %}
# Compute outputs
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "launch_template_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.main.latest_version
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}
{%- elif values.provider == 'azure' %}
# Compute outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group_name
}

output "network_security_group_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.main.id
}

output "vmss_id" {
  description = "ID of the virtual machine scale set"
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "vmss_name" {
  description = "Name of the virtual machine scale set"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}
{%- endif %}

{%- elif values.resource_type == 'network' %}
{%- if values.provider == 'aws' %}
# Network outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}
{%- endif %}

{%- elif values.resource_type == 'database' %}
{%- if values.provider == 'aws' %}
# Database outputs
output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "RDS instance database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_subnet_group_id" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.id
}

output "db_security_group_id" {
  description = "DB security group ID"
  value       = aws_security_group.rds.id
}

output "db_parameter_group_id" {
  description = "DB parameter group ID"
  value       = aws_db_parameter_group.main.id
}

output "db_password_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
  sensitive   = true
}
{%- endif %}

{%- elif values.resource_type == 'storage' %}
{%- if values.provider == 'aws' %}
# Storage outputs
output "s3_bucket_id" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}
{%- endif %}
{%- endif %}

{%- if values.enable_compliance %}
# Compliance outputs
{%- if values.provider == 'aws' %}
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = var.enable_monitoring ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_home_region" {
  description = "Region in which the CloudTrail was created"
  value       = var.enable_monitoring ? aws_cloudtrail.main[0].home_region : null
}
{%- endif %}
{%- endif %}

# Monitoring outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.main[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.main[0].arn : null
}

# Random ID for reference
output "random_suffix" {
  description = "Random suffix used for unique resource names"
  value       = random_id.suffix.hex
}
