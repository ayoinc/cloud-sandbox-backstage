locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Service account IDs are limited to 30 characters.
  sa_prefix = trimsuffix(substr(local.name_prefix, 0, 24), "-")

  # Production-like environments are protected against accidental deletion.
  is_production = contains(["prod", "dr"], var.environment)

  # Label keys and values may only contain lowercase letters, digits,
  # underscores and hyphens.
  labels = merge(
    {
      for key, value in var.labels :
      lower(replace(key, "/[^a-zA-Z0-9_-]/", "-")) => lower(replace(value, "/[^a-zA-Z0-9_-]/", "-"))
    },
    {
      project     = var.project_name
      component   = lower(replace(var.component_name, "/[^a-zA-Z0-9_-]/", "-"))
      environment = var.environment
      managed-by  = "terraform"
    }
  )

  network_name = var.enable_networking ? google_compute_network.main[0].name : var.existing_network
  network_id   = "projects/${var.project_id}/global/networks/${local.network_name}"

  # Subnet of the primary region used by the Compute Engine instances.
  primary_subnets = [for subnet in google_compute_subnetwork.main : subnet.name if subnet.region == var.region]
  subnetwork_id = format(
    "projects/%s/regions/%s/subnetworks/%s",
    var.project_id,
    var.region,
    length(local.primary_subnets) > 0 ? local.primary_subnets[0] : var.existing_subnetwork
  )

  # Cloud SQL and Memorystore Redis reach the network through private service access.
  needs_private_service_access = var.enable_database && var.create_private_service_access

  # APIs required by the enabled categories.
  services = toset(concat(
    ["cloudresourcemanager.googleapis.com", "iam.googleapis.com"],
    var.enable_networking || var.enable_compute ? ["compute.googleapis.com"] : [],
    var.enable_containers ? ["compute.googleapis.com", "container.googleapis.com", "artifactregistry.googleapis.com"] : [],
    var.enable_storage ? ["storage.googleapis.com"] : [],
    var.enable_storage && var.enable_filestore ? ["file.googleapis.com"] : [],
    var.enable_database ? ["compute.googleapis.com", "sqladmin.googleapis.com", "servicenetworking.googleapis.com", "secretmanager.googleapis.com"] : [],
    var.enable_database && var.enable_firestore ? ["firestore.googleapis.com"] : [],
    var.enable_database && var.enable_redis ? ["redis.googleapis.com"] : [],
    var.enable_security ? ["cloudkms.googleapis.com", "secretmanager.googleapis.com"] : [],
    var.enable_monitoring ? ["monitoring.googleapis.com", "logging.googleapis.com"] : [],
    var.enable_analytics ? ["bigquery.googleapis.com", "pubsub.googleapis.com"] : [],
    var.enable_ai_ml ? ["aiplatform.googleapis.com", "storage.googleapis.com"] : [],
    var.enable_serverless ? ["run.googleapis.com"] : [],
  ))
}

# Suffix for names that must be globally unique or cannot be reused after deletion.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_project_service" "main" {
  for_each = local.services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
