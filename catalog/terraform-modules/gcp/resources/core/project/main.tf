terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  parent_type = var.folder_id != null ? "folders" : "organizations"
  parent_id   = var.folder_id != null ? var.folder_id : var.org_id

  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "google_project" "project" {
  name            = var.project_name
  project_id      = var.project_id
  org_id          = var.folder_id == null ? var.org_id : null
  folder_id       = var.folder_id
  billing_account = var.billing_account

  auto_create_network = var.auto_create_network

  labels = merge(local.default_labels, var.labels)
}

resource "google_project_service" "apis" {
  for_each = toset(var.activate_apis)

  project = google_project.project.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_default_service_accounts" "default" {
  count = var.default_service_account != "KEEP" ? 1 : 0

  project        = google_project.project.project_id
  action         = var.default_service_account
  restore_policy = "REVERT_AND_IGNORE_FAILURE"

  depends_on = [google_project_service.apis]
}

resource "google_compute_project_metadata" "metadata" {
  count = length(var.project_metadata) > 0 ? 1 : 0

  project  = google_project.project.project_id
  metadata = var.project_metadata

  depends_on = [google_project_service.apis]
}
