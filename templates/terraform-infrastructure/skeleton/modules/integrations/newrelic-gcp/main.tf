# The account of the provider configuration, looked up only when no account ID
# is passed in. Its id is the account ID.
data "newrelic_account" "current" {
  count = var.newrelic_account_id == null ? 1 : 0
}

locals {
  newrelic_account_id = var.newrelic_account_id != null ? var.newrelic_account_id : tonumber(data.newrelic_account.current[0].id)
}

# Links the project without a service account key: New Relic presents an
# OpenID Connect token to the workload identity pool and impersonates the
# service account.
resource "newrelic_cloud_gcp_link_account" "this" {
  account_id = local.newrelic_account_id
  name       = "${var.name_prefix}-gcp"
  project_id = local.project_id

  use_workload_identity_federation = true
  audience                         = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.newrelic.name}"
  service_account_email            = google_service_account.newrelic.email

  depends_on = [time_sleep.iam_propagation]
}

# The services this stack can create. Each block needs the matching
# permissions in local.integration_permissions (identity.tf).
resource "newrelic_cloud_gcp_dm_integrations" "this" {
  account_id        = local.newrelic_account_id
  linked_account_id = newrelic_cloud_gcp_link_account.this.id

  # Network: Cloud Router and Cloud NAT
  router {}

  # Load balancing and Cloud CDN
  load_balancing {}

  # Kubernetes: GKE clusters and their node VMs
  kubernetes {}
  virtual_machines {}

  # Managed databases: Cloud SQL and Memorystore for Redis
  sql {}
  redis {}

  # Object storage
  storage {}
}
