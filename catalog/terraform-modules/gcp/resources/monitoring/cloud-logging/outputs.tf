output "log_bucket_ids" {
  description = "Map of log bucket IDs"
  value       = { for k, v in google_logging_project_bucket_config.buckets : k => v.id }
}

output "log_sink_ids" {
  description = "Map of log sink IDs"
  value       = { for k, v in google_logging_project_sink.sinks : k => v.id }
}

output "log_sink_writer_identities" {
  description = "Map of log sink writer identities for granting destination permissions"
  value       = { for k, v in google_logging_project_sink.sinks : k => v.writer_identity }
}

output "log_exclusion_ids" {
  description = "Map of log exclusion IDs"
  value       = { for k, v in google_logging_project_exclusion.exclusions : k => v.id }
}

output "log_metric_ids" {
  description = "Map of log metric IDs"
  value       = { for k, v in google_logging_metric.metrics : k => v.id }
}
