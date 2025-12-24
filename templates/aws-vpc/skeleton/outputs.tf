# =============================================================================
# AWS VPC - Root Outputs
# =============================================================================
# Outputs from the root module, exposing values from the VPC child module.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# -----------------------------------------------------------------------------
# Subnet Outputs
# -----------------------------------------------------------------------------
output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = module.vpc.public_subnet_cidr_blocks
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = module.vpc.private_subnet_cidr_blocks
}

# -----------------------------------------------------------------------------
# Gateway Outputs
# -----------------------------------------------------------------------------
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = module.vpc.nat_gateway_public_ips
}

# -----------------------------------------------------------------------------
# Route Table Outputs
# -----------------------------------------------------------------------------
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

# -----------------------------------------------------------------------------
# Flow Logs Outputs
# -----------------------------------------------------------------------------
output "flow_log_id" {
  description = "The ID of the VPC Flow Log"
  value       = module.vpc.flow_log_id
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for flow logs"
  value       = module.vpc.flow_log_cloudwatch_log_group_arn
}

# -----------------------------------------------------------------------------
# Availability Zone Outputs
# -----------------------------------------------------------------------------
output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}
