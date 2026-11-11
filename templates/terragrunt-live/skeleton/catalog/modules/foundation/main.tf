{%- if values.cloud == 'aws' -%}
# Customer managed key that the other units encrypt with. The provider adds the
# tags of the stack through default_tags.
resource "aws_kms_key" "main" {
  description             = "Encrypts the data of ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = var.key_deletion_window_days
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.main.key_id
}
{%- elif values.cloud == 'azure' -%}
# Resource group that the other units deploy into.
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.name}"
  location = var.region
  tags     = var.tags
}
{%- else -%}
data "google_storage_project_service_account" "current" {}

# Customer managed key that the other units encrypt with. Key rings cannot be
# deleted, so destroying this unit leaves an empty key ring behind.
resource "google_kms_key_ring" "main" {
  name     = var.name
  location = var.region
}

resource "google_kms_crypto_key" "logs" {
  name            = "logs"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = var.key_rotation_period
}

# Cloud Storage encrypts with the key through its service agent.
resource "google_kms_crypto_key_iam_member" "storage" {
  crypto_key_id = google_kms_crypto_key.logs.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = data.google_storage_project_service_account.current.member
}
{%- endif %}
