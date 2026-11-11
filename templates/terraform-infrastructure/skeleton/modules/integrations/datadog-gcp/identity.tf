# The project of the provider configuration, read only when no project ID is passed in.
data "google_client_config" "current" {
  count = var.project_id == null ? 1 : 0
}

locals {
  project_id = var.project_id != null ? var.project_id : data.google_client_config.current[0].project
}

locals {
  # APIs Datadog calls in the project, plus the two that issue the short-lived
  # tokens of the impersonated service account.
  services = toset([
    "cloudasset.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "monitoring.googleapis.com",
  ])

  # Read-only roles Datadog documents for metric and resource collection.
  roles = toset([
    "roles/browser",
    "roles/cloudasset.viewer",
    "roles/compute.viewer",
    "roles/monitoring.viewer",
  ])
}

resource "google_project_service" "required" {
  for_each = local.services

  project = local.project_id
  service = each.value

  # Other parts of the stack use the same APIs: leave them on when this module is removed.
  disable_on_destroy = false
}

# Identity Datadog impersonates. It has no key: Datadog exchanges its own
# identity for short-lived tokens of this account.
resource "google_service_account" "datadog" {
  project      = local.project_id
  account_id   = "${var.name_prefix}-ddog"
  display_name = "Datadog integration"
  description  = "Impersonated by Datadog to read metrics and resource metadata of this project."

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "datadog" {
  for_each = local.roles

  project = local.project_id
  role    = each.value
  member  = google_service_account.datadog.member
}

# Only the principal Datadog generated for this organisation may mint tokens,
# and only for this service account.
resource "google_service_account_iam_member" "datadog_impersonation" {
  service_account_id = google_service_account.datadog.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${datadog_integration_gcp_sts.this.delegate_account_email}"
}
