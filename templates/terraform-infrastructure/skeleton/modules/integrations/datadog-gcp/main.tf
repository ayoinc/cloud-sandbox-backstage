# Registers the service account in Datadog, which returns the principal that
# will impersonate it. Datadog monitors every project the account can read.
resource "datadog_integration_gcp_sts" "this" {
  client_email = google_service_account.datadog.email
  account_tags = [for key, value in var.tags : "${key}:${value}"]

  automute                    = true
  resource_collection_enabled = true
  is_cspm_enabled             = false
}
