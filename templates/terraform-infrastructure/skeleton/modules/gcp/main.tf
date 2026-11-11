locals {
  is_production = var.environment == "production"

  # Google Cloud labels allow lowercase letters, digits, underscores and
  # hyphens, at most 63 characters, and keys must start with a letter. Tags
  # whose keys become equal after the conversion keep the first value.
  label_groups = {
    for key, value in var.tags :
    substr(can(regex("^[a-z]", lower(key))) ? replace(lower(key), "/[^a-z0-9_-]/", "-") : "tag-${replace(lower(key), "/[^a-z0-9_-]/", "-")}", 0, 63)
    => substr(replace(lower(value), "/[^a-z0-9_-]/", "-"), 0, 63)...
  }
  labels = { for key, values in local.label_groups : key => values[0] }

  # Globally unique names (buckets) and names that cannot be reused for days
  # after deletion (Cloud SQL instances, key rings, log buckets) end in this.
  suffix = random_id.suffix.hex

  # Components
  cloud_sql       = var.enable_database && contains(["postgresql", "mysql"], var.database_type)
  redis           = var.enable_database && var.database_type == "redis"
  registry        = contains(["container-platform", "ml-platform", "serverless-platform"], var.infrastructure_type)
  data_lake       = contains(["data-platform", "ml-platform"], var.infrastructure_type)
  private_dns     = var.infrastructure_type == "networking-foundation"
  log_destination = var.enable_monitoring || var.require_flow_logs
  has_buckets     = var.enable_storage || local.data_lake
  replication     = var.enable_disaster_recovery && local.has_buckets

  # Cloud SQL and Memorystore get private addresses from a range reserved in
  # the network and peered with Google's service network.
  private_services_access = (local.cloud_sql || local.redis) && var.create_private_services_access

  # Flow logs of a network this module does not create are configured on the
  # network as a whole, because its subnets are managed elsewhere.
  existing_network_flow_logs = var.require_flow_logs && !var.enable_networking && var.existing_network != null

  uses_compute = (
    var.enable_networking || local.tier_rules || var.enable_kubernetes ||
    var.enable_cdn || var.enable_waf || local.private_services_access
  )
  uses_service_accounts = var.enable_kubernetes || var.enable_cdn || var.enable_managed_prometheus
  uses_project_number   = var.enable_kms || var.enable_alerting

  # The APIs of the features that are switched on.
  services = toset(concat(
    local.uses_compute ? ["compute.googleapis.com"] : [],
    local.uses_service_accounts ? ["iam.googleapis.com"] : [],
    local.uses_service_accounts || local.uses_project_number || local.replication ? ["cloudresourcemanager.googleapis.com"] : [],
    var.enable_kubernetes ? ["container.googleapis.com"] : [],
    var.enable_kubernetes && var.enable_backup ? ["gkebackup.googleapis.com"] : [],
    local.cloud_sql ? ["sqladmin.googleapis.com"] : [],
    local.redis ? ["redis.googleapis.com"] : [],
    local.private_services_access ? ["servicenetworking.googleapis.com"] : [],
    local.has_buckets ? ["storage.googleapis.com"] : [],
    local.replication ? ["storagetransfer.googleapis.com"] : [],
    local.replication || var.enable_alerting ? ["pubsub.googleapis.com"] : [],
    var.enable_secrets_manager ? ["secretmanager.googleapis.com"] : [],
    var.enable_kms ? ["cloudkms.googleapis.com"] : [],
    var.enable_backup ? ["backupdr.googleapis.com"] : [],
    local.log_destination ? ["logging.googleapis.com"] : [],
    var.enable_monitoring || var.enable_alerting || var.enable_managed_prometheus ? ["monitoring.googleapis.com"] : [],
    local.registry ? ["artifactregistry.googleapis.com"] : [],
    local.private_dns ? ["dns.googleapis.com"] : [],
    local.existing_network_flow_logs ? ["networkmanagement.googleapis.com"] : [],
  ))
}

resource "random_id" "suffix" {
  byte_length = 3
}

# The APIs stay enabled when the stack is destroyed, because other workloads
# in the project may rely on them.
resource "google_project_service" "this" {
  for_each = local.services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# A newly enabled API rejects calls for a short while. Every resource waits
# for this pause, so one apply works on a fresh project.
resource "time_sleep" "api_propagation" {
  create_duration = "60s"

  triggers = {
    services = join(",", sort(tolist(local.services)))
  }

  depends_on = [google_project_service.this]
}

# The project ID as a value that is unknown until the API named by the key
# has been enabled and has settled, and known from then on. Data sources take
# the project from here: on the first apply they are read after their API is
# usable, and on later plans they are read at plan time, so values derived
# from them do not change.
resource "terraform_data" "api_ready" {
  for_each = local.services

  input = var.project_id

  depends_on = [time_sleep.api_propagation]
}

# The project number is part of the email address of Google's service agents.
data "google_project" "this" {
  count = local.uses_project_number ? 1 : 0

  project_id = terraform_data.api_ready["cloudresourcemanager.googleapis.com"].output
}
