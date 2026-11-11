# -----------------------------------------------------------------------------
# Key management: Cloud KMS key ring with a rotating key
# -----------------------------------------------------------------------------

resource "google_project_service" "kms" {
  project            = local.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

# Key rings cannot be deleted, so the name carries the unique suffix to keep
# a recreated component from colliding with its predecessor.
resource "google_kms_key_ring" "this" {
  project  = local.project_id
  name     = module.naming.global["kms"]
  location = var.region

  depends_on = [google_project_service.kms]
}

resource "google_kms_crypto_key" "this" {
  name            = "main"
  key_ring        = google_kms_key_ring.this.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"
}

output "kms_key_ring_id" {
  description = "ID of the Cloud KMS key ring."
  value       = google_kms_key_ring.this.id
}

output "kms_key_id" {
  description = "ID of the Cloud KMS key."
  value       = google_kms_crypto_key.this.id
}
