# -----------------------------------------------------------------------------
# Log workspace: Cloud Logging bucket
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Number of days logs are kept, between 1 and 3650."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3650
    error_message = "log_retention_days must be between 1 and 3650."
  }
}

resource "google_project_service" "logging" {
  project            = local.project_id
  service            = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_logging_project_bucket_config" "this" {
  project        = local.project_id
  location       = var.region
  bucket_id      = module.naming.standard["log"]
  retention_days = var.log_retention_days
  description    = "Logs of the ${var.component_name} component"

  depends_on = [google_project_service.logging]
}

output "log_bucket_id" {
  description = "ID of the Cloud Logging bucket."
  value       = google_logging_project_bucket_config.this.id
}
