# =============================================================================
# AWS VPC Module - Outputs
# =============================================================================
# Output values from the VPC module for use by other modules or resources.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

# -----------------------------------------------------------------------------
# Subnet Outputs
# -----------------------------------------------------------------------------
output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# -----------------------------------------------------------------------------
# Gateway Outputs
# -----------------------------------------------------------------------------
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# -----------------------------------------------------------------------------
# Route Table Outputs
# -----------------------------------------------------------------------------
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

# -----------------------------------------------------------------------------
# Flow Logs Outputs
# -----------------------------------------------------------------------------
output "flow_log_id" {
  description = "The ID of the VPC Flow Log"
  value       = var.enable_flow_logs ? aws_flow_log.this[0].id : null
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for flow logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

# -----------------------------------------------------------------------------
# Availability Zone Outputs
# -----------------------------------------------------------------------------
output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}
