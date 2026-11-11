# The project of the provider configuration, read only when no project ID is passed in.
data "google_client_config" "current" {
  count = var.project_id == null ? 1 : 0
}

locals {
  project_id = var.project_id != null ? var.project_id : data.google_client_config.current[0].project
}

locals {
  # APIs New Relic documents for keyless access: token exchange and
  # impersonation, metrics, and resource discovery.
  services = toset([
    "cloudasset.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "monitoring.googleapis.com",
    "sts.googleapis.com",
  ])

  # Predefined read-only roles: metrics, API usage attribution and resource discovery.
  roles = toset([
    "roles/cloudasset.viewer",
    "roles/monitoring.viewer",
    "roles/serviceusage.serviceUsageConsumer",
  ])

  # Inventory permissions New Relic documents for each enabled integration
  # (main.tf). Load balancing needs none.
  integration_permissions = {
    project          = ["resourcemanager.projects.get"]
    kubernetes       = ["container.clusters.list"]
    sql              = ["cloudsql.instances.list"]
    redis            = ["redis.instances.get", "redis.instances.list"]
    storage          = ["storage.buckets.list"]
    virtual_machines = ["compute.disks.get", "compute.disks.list", "compute.instances.list"]
    router           = ["compute.routers.get", "compute.routers.list"]
  }

  newrelic_oidc_issuers = {
    US = "https://oidc.newrelic.com/r/gcp-cmp"
    EU = "https://oidc.eu.newrelic.com/r/gcp-cmp"
    JP = "https://oidc.jp.newrelic.com/r/gcp-cmp"
  }

  # Service account descriptions hold at most 256 characters.
  description = substr(join("; ", concat(
    ["Impersonated by New Relic to read metrics and resource metadata of this project"],
    [for key, value in var.tags : "${key}=${value}"],
  )), 0, 256)
}

resource "google_project_service" "required" {
  for_each = local.services

  project = local.project_id
  service = each.value

  # Other parts of the stack use the same APIs: leave them on when this module is removed.
  disable_on_destroy = false
}

# Identity New Relic impersonates. It has no key.
resource "google_service_account" "newrelic" {
  project      = local.project_id
  account_id   = "${var.name_prefix}-relic"
  display_name = "New Relic integration"
  description  = local.description

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "newrelic" {
  for_each = local.roles

  project = local.project_id
  role    = each.value
  member  = google_service_account.newrelic.member
}

# New Relic accepts a custom role in place of the primitive Viewer role. This
# one holds the permissions New Relic documents for the enabled integrations.
resource "google_project_iam_custom_role" "newrelic" {
  project     = local.project_id
  role_id     = "${replace(var.name_prefix, "-", "_")}_newrelic_inventory"
  title       = "${var.name_prefix} New Relic inventory"
  description = "Lists the resources New Relic attaches metrics to."
  permissions = sort(flatten(values(local.integration_permissions)))

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "newrelic_inventory" {
  project = local.project_id
  role    = google_project_iam_custom_role.newrelic.id
  member  = google_service_account.newrelic.member
}

# A deleted pool keeps its ID reserved for 30 days: the suffix lets the module
# be removed and applied again within that time.
resource "random_id" "pool" {
  byte_length = 2
}

resource "google_iam_workload_identity_pool" "newrelic" {
  project                   = local.project_id
  workload_identity_pool_id = "nr-${var.name_prefix}-${random_id.pool.hex}"
  display_name              = "New Relic"
  description               = "Trusts tokens New Relic issues for account ${local.newrelic_account_id}."

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "newrelic" {
  project                            = local.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.newrelic.workload_identity_pool_id
  workload_identity_pool_provider_id = "newrelic"
  display_name                       = "New Relic"

  oidc {
    issuer_uri        = local.newrelic_oidc_issuers[var.newrelic_region]
    allowed_audiences = ["newrelic-gcp-integrations"]
  }

  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.nr_account_id" = "assertion.nr_account_id"
  }

  # Tokens of other New Relic accounts are rejected.
  attribute_condition = "assertion.nr_account_id == \"${local.newrelic_account_id}\""
}

# Only identities of the pool that carry this New Relic account ID may
# impersonate the service account.
resource "google_service_account_iam_member" "newrelic_impersonation" {
  service_account_id = google_service_account.newrelic.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.newrelic.name}/attribute.nr_account_id/${local.newrelic_account_id}"
}

# IAM bindings take effect after a delay, and New Relic impersonates the
# service account as soon as the project is linked.
resource "time_sleep" "iam_propagation" {
  create_duration = "90s"

  triggers = {
    impersonation = google_service_account_iam_member.newrelic_impersonation.id
    provider      = google_iam_workload_identity_pool_provider.newrelic.name
    inventory     = google_project_iam_member.newrelic_inventory.id
    roles         = join(",", [for role in sort(local.roles) : google_project_iam_member.newrelic[role].id])
  }
}
