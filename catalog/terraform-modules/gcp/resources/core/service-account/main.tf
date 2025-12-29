terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.account_id
  display_name = var.display_name != null ? var.display_name : var.account_id
  description  = var.description
}

resource "google_project_iam_member" "roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.this.email}"
}

resource "google_service_account_iam_member" "impersonators" {
  for_each = { for idx, imp in var.impersonators : "${imp.member}-${imp.role}" => imp }

  service_account_id = google_service_account.this.name
  role               = each.value.role
  member             = each.value.member
}

resource "google_service_account_key" "this" {
  count = var.create_key ? 1 : 0

  service_account_id = google_service_account.this.name
  key_algorithm      = var.key_algorithm
}
