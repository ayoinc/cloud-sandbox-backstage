#------------------------------------------------------------------------------
# Hosted Zone Outputs
#------------------------------------------------------------------------------
output "zone_id" {
  description = "The ID of the hosted zone"
  value       = aws_route53_zone.this.zone_id
}

output "zone_arn" {
  description = "The ARN of the hosted zone"
  value       = aws_route53_zone.this.arn
}

output "name_servers" {
  description = "A list of name servers for the hosted zone (only for public zones)"
  value       = var.private_zone ? [] : aws_route53_zone.this.name_servers
}

output "zone_name" {
  description = "The name of the hosted zone"
  value       = aws_route53_zone.this.name
}

#------------------------------------------------------------------------------
# Additional Outputs
#------------------------------------------------------------------------------
output "primary_name_server" {
  description = "The primary name server for the hosted zone"
  value       = aws_route53_zone.this.primary_name_server
}

output "standard_record_fqdns" {
  description = "Map of standard record FQDNs"
  value = {
    for key, record in aws_route53_record.standard :
    key => record.fqdn
  }
}

output "alias_record_fqdns" {
  description = "Map of alias record FQDNs"
  value = {
    for key, record in aws_route53_record.alias :
    key => record.fqdn
  }
}

output "is_private_zone" {
  description = "Whether this is a private hosted zone"
  value       = var.private_zone
}
