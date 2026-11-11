locals {
  short_environment = {
    development = "dev"
    staging     = "stg"
    production  = "prod"
  }[var.environment]
}

# Suffix for names that must be unique across the whole cloud.
resource "random_id" "suffix" {
  byte_length = 4
}

module "naming" {
  source = "./modules/naming"

  convention     = var.naming_convention
  company        = var.company
  team           = var.business_unit
  project        = var.project_name
  environment    = local.short_environment
  unique_suffix  = random_id.suffix.hex
  resource_types = ["prj", "gcs", "gcsdr", "vpc", "kms", "ar", "log", "vm"]
}

module "tagging" {
  source = "./modules/tagging"

  component_name  = var.component_name
  component_type  = var.component_type
  project         = var.project_name
  environment     = var.environment
  business_unit   = var.business_unit
  cost_center     = var.cost_center
  application_id  = var.application_id
  owner           = var.owner
  additional_tags = var.additional_tags
}

# Project IDs are unique across Google Cloud and limited to 30 characters.
resource "google_project" "this" {
  count = var.create_resource_container ? 1 : 0

  name            = module.naming.short["prj"]
  project_id      = module.naming.global_short["prj"]
  folder_id       = var.folder_id
  billing_account = var.billing_account
  deletion_policy = var.environment == "production" ? "PREVENT" : "DELETE"

  # The default network comes with permissive firewall rules.
  auto_create_network = false

  lifecycle {
    precondition {
      condition     = var.folder_id != "" && var.billing_account != ""
      error_message = "Creating the project needs folder_id and billing_account. Set them, or set create_resource_container to false and project_id to an existing project."
    }
  }
}

data "google_project" "existing" {
  count = var.create_resource_container ? 0 : 1

  project_id = var.project_id

  lifecycle {
    precondition {
      condition     = var.project_id != ""
      error_message = "Set project_id to an existing project, or set create_resource_container to true."
    }
  }
}

locals {
  project_id = var.create_resource_container ? google_project.this[0].project_id : data.google_project.existing[0].project_id
}
