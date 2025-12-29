output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IP addresses of the NAT Gateways"
  value       = aws_nat_gateway.this[*].public_ip
}

output "eip_ids" {
  description = "List of Elastic IP IDs created for the NAT Gateways"
  value       = aws_eip.this[*].id
}

output "eip_public_ips" {
  description = "List of Elastic IP public addresses"
  value       = aws_eip.this[*].public_ip
}
