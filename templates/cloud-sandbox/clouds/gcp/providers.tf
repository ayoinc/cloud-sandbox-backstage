provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = merge(var.labels, {
    environment = var.environment
    managed-by  = "terraform"
    project     = var.name
  })
}
