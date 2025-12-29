output "zone_id" {
  description = "The ID of the DNS managed zone"
  value       = google_dns_managed_zone.this.id
}

output "zone_name" {
  description = "The name of the DNS managed zone"
  value       = google_dns_managed_zone.this.name
}

output "name_servers" {
  description = "The list of name servers for the DNS zone"
  value       = google_dns_managed_zone.this.name_servers
}

output "dns_policy_ids" {
  description = "Map of DNS policy names to their IDs"
  value       = { for k, v in google_dns_policy.this : k => v.id }
}
