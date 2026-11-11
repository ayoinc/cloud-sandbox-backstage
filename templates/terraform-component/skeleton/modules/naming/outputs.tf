output "standard" {
  description = "Names by resource type, at most 63 characters."
  value       = local.standard
}

output "short" {
  description = "Names by resource type, at most 24 characters, for services with short limits."
  value       = local.short
}

output "global" {
  description = "Names by resource type with the unique suffix, at most 63 characters, for globally unique names such as buckets."
  value       = local.global
}

output "global_short" {
  description = "Names by resource type with the unique suffix, at most 30 characters, for globally unique names with short limits such as project IDs."
  value       = local.global_short
}

output "global_compact" {
  description = "Names by resource type without hyphens and with the unique suffix, at most 24 characters, for services that allow only letters and digits."
  value       = local.global_compact
}
