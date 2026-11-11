# -----------------------------------------------------------------------------
# BI integration. Looker Studio and Looker connect to BigQuery and need no
# infrastructure of their own. This creates what makes them fast and safe to
# connect: a BI Engine reservation that keeps frequently used data in memory, and
# a read-only identity for the BI tool's connection.
# -----------------------------------------------------------------------------

module "bi_service_account" {
  count  = local.bi_enabled ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/core/service-account?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  account_id   = "${local.short_prefix}-bi"
  display_name = "${local.name_prefix} BI tools"
  description  = "Read-only identity that Looker or Looker Studio connects to BigQuery with"

  depends_on = [google_project_service.apis]
}

resource "google_bigquery_bi_reservation" "this" {
  count = local.bi_enabled ? 1 : 0

  location = var.region
  size     = local.bi_engine_memory_gb[var.warehouse_size] * 1024 * 1024 * 1024

  depends_on = [google_project_service.apis]
}

# -----------------------------------------------------------------------------
# ML platform: a Vertex AI Workbench instance (JupyterLab) in the private subnet,
# its identity and a bucket for models, pipeline runs and other artifacts.
# -----------------------------------------------------------------------------

module "ml_service_account" {
  count  = var.enable_ml_platform ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/core/service-account?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  account_id   = "${local.short_prefix}-ml"
  display_name = "${local.name_prefix} machine learning"
  description  = "Identity of the Workbench instance and of Vertex AI jobs of ${local.name_prefix}"

  project_roles = ["roles/aiplatform.user"]

  depends_on = [google_project_service.apis]
}

locals {
  ml_buckets = var.enable_ml_platform ? {
    ml-artifacts = {
      name               = "ml"
      versioning         = true
      force_destroy      = !local.is_production
      transition_class   = null
      expire_after_days  = null
      object_role        = "roles/storage.objectUser"
      object_role_member = "serviceAccount:${module.ml_service_account[0].service_account_email}"
    }
  } : {}
}

resource "google_workbench_instance" "this" {
  count = var.enable_ml_platform ? 1 : 0

  name     = "${local.name_prefix}-workbench"
  location = coalesce(var.ml_zone, "${var.region}-b")

  gce_setup {
    machine_type      = var.ml_machine_type
    disable_public_ip = true

    service_accounts {
      email = module.ml_service_account[0].service_account_email
    }

    network_interfaces {
      network = module.network[0].network_id
      subnet  = module.network[0].subnet_ids["data"]
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_vtpm                 = true
      enable_integrity_monitoring = true
    }

    metadata = {
      idle-timeout-seconds = tostring(var.ml_idle_shutdown_seconds)
    }
  }

  depends_on = [google_project_service.apis, module.ml_service_account]
}

# People open JupyterLab by acting as the instance's identity.
resource "google_service_account_iam_member" "workbench_users" {
  for_each = var.enable_ml_platform ? toset(var.data_scientists) : toset([])

  service_account_id = module.ml_service_account[0].service_account_name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
