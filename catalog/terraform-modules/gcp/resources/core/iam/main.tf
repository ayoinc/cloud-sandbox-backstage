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
  # Flatten project IAM bindings for iteration
  project_iam_bindings_flat = flatten([
    for binding in var.project_iam_bindings : [
      for member in binding.members : {
        role      = binding.role
        member    = member
        condition = binding.condition
      }
    ]
  ])

  # Flatten organization IAM bindings for iteration
  organization_iam_bindings_flat = flatten([
    for binding in var.organization_iam_bindings : [
      for member in binding.members : {
        role      = binding.role
        member    = member
        condition = binding.condition
      }
    ]
  ])

  # Flatten folder IAM bindings for iteration
  folder_iam_bindings_flat = flatten([
    for binding in var.folder_iam_bindings : [
      for member in binding.members : {
        role      = binding.role
        member    = member
        condition = binding.condition
      }
    ]
  ])
}

# Project-level IAM bindings
resource "google_project_iam_member" "project_bindings" {
  for_each = {
    for idx, binding in local.project_iam_bindings_flat :
    "${binding.role}-${binding.member}" => binding
  }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Custom roles
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = {
    for role in var.custom_roles : role.role_id => role
  }

  project     = var.project_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
}

# Organization-level IAM bindings (optional)
resource "google_organization_iam_member" "organization_bindings" {
  for_each = var.organization_id != null ? {
    for idx, binding in local.organization_iam_bindings_flat :
    "${binding.role}-${binding.member}" => binding
  } : {}

  org_id = var.organization_id
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Folder-level IAM bindings (optional)
resource "google_folder_iam_member" "folder_bindings" {
  for_each = var.folder_id != null ? {
    for idx, binding in local.folder_iam_bindings_flat :
    "${binding.role}-${binding.member}" => binding
  } : {}

  folder = var.folder_id
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}
