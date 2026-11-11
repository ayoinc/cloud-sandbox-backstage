provider "google" {
  region         = var.region
  default_labels = module.tagging.labels
}
