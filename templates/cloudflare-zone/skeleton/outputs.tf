# =============================================================================
# Cloudflare Zone - Outputs
# =============================================================================

output "zone_id" {
  description = "ID of the zone."
  value       = local.zone_id
}

output "name_servers" {
  description = "Name servers to set at the registrar. Null when the zone was not created by this configuration."
  value       = one(cloudflare_zone.this[*].name_servers)
}

output "dnssec_ds_record" {
  description = "DS record to add at the registrar to complete DNSSEC. Null when DNSSEC is disabled."
  value       = one(cloudflare_zone_dnssec.this[*].ds)
}

output "dns_records" {
  description = "Names of the managed DNS records, by key."
  value       = { for key, record in cloudflare_dns_record.this : key => record.name }
}
