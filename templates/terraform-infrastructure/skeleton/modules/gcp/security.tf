locals {
  # Firewall rules select instances by these network tags. Attach them to the
  # instances of each tier.
  tier_tags = {
    web  = "${var.name_prefix}-web"
    app  = "${var.name_prefix}-app"
    data = "${var.name_prefix}-data"
  }
  gke_node_tag = "${var.name_prefix}-gke-node"

  # Without a network there is nothing to put rules on.
  tier_rules    = var.enable_security_group_rules && local.network_available
  flat_rule     = !var.enable_security_group_rules && var.enable_networking
  data_clients  = concat([local.tier_tags.app], var.enable_kubernetes ? [local.gke_node_tag] : [])
  data_ports    = ["5432", "3306", "6379"]
  managed_rules = local.tier_rules && local.private_services_access

  # Range the managed data stores take their addresses from.
  private_services_range = (
    !local.private_services_access ? null :
    var.enable_networking ? local.private_services_cidr :
    "${google_compute_global_address.private_services[0].address}/${google_compute_global_address.private_services[0].prefix_length}"
  )

  # Google front ends and health checkers reach backends from these ranges.
  load_balancer_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

# -----------------------------------------------------------------------------
# Firewall
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "internal" {
  count = local.flat_rule ? 1 : 0

  project       = var.project_id
  name          = "${var.name_prefix}-allow-internal"
  network       = local.network_id
  description   = "Traffic between resources inside the network range"
  direction     = "INGRESS"
  source_ranges = [var.network_cidr]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "web" {
  count = local.tier_rules ? 1 : 0

  project       = var.project_id
  name          = "${var.name_prefix}-web-ingress"
  network       = local.network_id
  description   = "HTTPS to the web tier from the allowed clients and Google load balancers"
  direction     = "INGRESS"
  source_ranges = distinct(concat(local.load_balancer_ranges, var.allowed_ingress_cidrs))
  target_tags   = [local.tier_tags.web]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  depends_on = [time_sleep.api_propagation]
}

resource "google_compute_firewall" "app" {
  count = local.tier_rules ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-app-from-web"
  network     = local.network_id
  description = "Application port of the app tier from the web tier"
  direction   = "INGRESS"
  source_tags = [local.tier_tags.web]
  target_tags = [local.tier_tags.app]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }

  depends_on = [time_sleep.api_propagation]
}

resource "google_compute_firewall" "data" {
  count = local.tier_rules ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-data-from-app"
  network     = local.network_id
  description = "Database ports of self-managed data tier instances from the app tier and the cluster nodes"
  direction   = "INGRESS"
  source_tags = local.data_clients
  target_tags = [local.tier_tags.data]

  allow {
    protocol = "tcp"
    ports    = local.data_ports
  }

  depends_on = [time_sleep.api_propagation]
}

# Cloud SQL and Memorystore live in Google's peered network, where ingress
# rules of this network do not apply. Access is restricted on the way out:
# only the app tier and the cluster nodes may open connections to them.
resource "google_compute_firewall" "managed_data_allow" {
  count = local.managed_rules ? 1 : 0

  project            = var.project_id
  name               = "${var.name_prefix}-managed-data-allow"
  network            = local.network_id
  description        = "App tier and cluster nodes to the managed data stores"
  direction          = "EGRESS"
  priority           = 1000
  destination_ranges = [local.private_services_range]
  target_tags        = local.data_clients

  allow {
    protocol = "tcp"
    ports    = local.data_ports
  }
}

resource "google_compute_firewall" "managed_data_deny" {
  count = local.managed_rules ? 1 : 0

  project            = var.project_id
  name               = "${var.name_prefix}-managed-data-deny"
  network            = local.network_id
  description        = "Every other instance is refused access to the managed data stores"
  direction          = "EGRESS"
  priority           = 2000
  destination_ranges = [local.private_services_range]

  deny {
    protocol = "all"
  }

  dynamic "log_config" {
    for_each = var.enable_monitoring ? [1] : []

    content {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }
}

# -----------------------------------------------------------------------------
# Cloud KMS
# -----------------------------------------------------------------------------

locals {
  # A key can only protect resources in its own location, so disaster
  # recovery adds a second key in the secondary region.
  kms_key_locations = {
    for name, location in { primary = var.region, secondary = var.secondary_region } :
    name => location
    if var.enable_kms && (name == "primary" || var.enable_disaster_recovery)
  }

  # Key of the resources in the primary and in the secondary region.
  kms_key_id           = var.enable_kms ? google_kms_crypto_key.this["primary"].id : null
  kms_secondary_key_id = var.enable_kms && var.enable_disaster_recovery ? google_kms_crypto_key.this["secondary"].id : null

  # Service agents that are created on request. The others exist as soon as
  # their API is enabled.
  service_identities = toset(var.enable_kms ? concat(
    local.cloud_sql ? ["sqladmin.googleapis.com"] : [],
    local.redis ? ["redis.googleapis.com"] : [],
    var.enable_secrets_manager ? ["secretmanager.googleapis.com"] : [],
    local.registry ? ["artifactregistry.googleapis.com"] : [],
    var.enable_kubernetes && var.enable_backup ? ["gkebackup.googleapis.com"] : [],
    local.sql_backup_plan ? ["backupdr.googleapis.com"] : [],
  ) : [])

  project_number = local.uses_project_number ? data.google_project.this[0].number : ""
  service_agents = {
    for name, domain in {
      sql        = "gcp-sa-cloud-sql"
      redis      = "cloud-redis"
      secrets    = "gcp-sa-secretmanager"
      registry   = "gcp-sa-artifactregistry"
      gke        = "container-engine-robot"
      compute    = "compute-system"
      gke_backup = "gcp-sa-gkebackup"
      backup     = "gcp-sa-backupdr"
      alerts     = "gcp-sa-monitoring-notification"
    } : name => "serviceAccount:service-${local.project_number}@${domain}.iam.gserviceaccount.com"
  }
  storage_agent = one(data.google_storage_project_service_account.this[*].member)
  logging_agent = one(data.google_logging_project_cmek_settings.this[*].service_account_id)

  # Which service agent may use which key.
  kms_grant_catalog = {
    primary-storage      = { key = "primary", member = local.storage_agent, enabled = local.has_buckets }
    primary-logging      = { key = "primary", member = local.logging_agent == null ? null : "serviceAccount:${local.logging_agent}", enabled = local.log_destination }
    primary-sql          = { key = "primary", member = local.service_agents.sql, enabled = local.cloud_sql }
    primary-sql-backup   = { key = "primary", member = local.service_agents.backup, enabled = local.sql_backup_plan }
    primary-redis        = { key = "primary", member = local.service_agents.redis, enabled = local.redis }
    primary-secrets      = { key = "primary", member = local.service_agents.secrets, enabled = var.enable_secrets_manager }
    primary-registry     = { key = "primary", member = local.service_agents.registry, enabled = local.registry }
    primary-gke          = { key = "primary", member = local.service_agents.gke, enabled = var.enable_kubernetes }
    primary-compute      = { key = "primary", member = local.service_agents.compute, enabled = var.enable_kubernetes }
    primary-gke-backup   = { key = "primary", member = local.service_agents.gke_backup, enabled = var.enable_kubernetes && var.enable_backup && !var.enable_disaster_recovery }
    secondary-storage    = { key = "secondary", member = local.storage_agent, enabled = local.replication }
    secondary-sql        = { key = "secondary", member = local.service_agents.sql, enabled = local.sql_replica }
    secondary-secrets    = { key = "secondary", member = local.service_agents.secrets, enabled = var.enable_secrets_manager && var.enable_disaster_recovery }
    secondary-gke-backup = { key = "secondary", member = local.service_agents.gke_backup, enabled = var.enable_kubernetes && var.enable_backup && var.enable_disaster_recovery }
  }
  kms_grants = { for name, grant in local.kms_grant_catalog : name => grant if var.enable_kms && grant.enabled }
}

# Key rings can never be deleted, so the name carries the random suffix to
# let a recreated stack start with a new one.
resource "google_kms_key_ring" "this" {
  for_each = local.kms_key_locations

  project  = var.project_id
  name     = "${var.name_prefix}-${local.suffix}"
  location = each.value

  depends_on = [time_sleep.api_propagation]
}

resource "google_kms_crypto_key" "this" {
  for_each = local.kms_key_locations

  name            = "${var.name_prefix}-data"
  key_ring        = google_kms_key_ring.this[each.key].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"
  labels          = local.labels
  deletion_policy = var.require_deletion_protection ? "PREVENT" : "DELETE"
}

resource "google_project_service_identity" "this" {
  provider = google-beta
  for_each = local.service_identities

  project = var.project_id
  service = each.value

  depends_on = [time_sleep.api_propagation]
}

data "google_storage_project_service_account" "this" {
  count = (var.enable_kms && local.has_buckets) || local.replication ? 1 : 0

  project = terraform_data.api_ready["storage.googleapis.com"].output
}

data "google_logging_project_cmek_settings" "this" {
  count = var.enable_kms && local.log_destination ? 1 : 0

  project = terraform_data.api_ready["logging.googleapis.com"].output
}

resource "google_kms_crypto_key_iam_member" "this" {
  for_each = local.kms_grants

  crypto_key_id = google_kms_crypto_key.this[each.value.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value.member

  depends_on = [google_project_service_identity.this]
}

# IAM changes take a moment to reach the services that use the keys.
resource "time_sleep" "kms_iam_propagation" {
  count = var.enable_kms ? 1 : 0

  create_duration = "30s"

  triggers = {
    grants = join(",", keys(local.kms_grants))
  }

  depends_on = [google_kms_crypto_key_iam_member.this]
}
