# Runs with `tofu test`. The provider is mocked: no credentials are needed and
# nothing is created.

{%- if values.cloud == 'aws' %}
mock_provider "aws" {}

variables {
  name = "sample-dev"
}

run "key_rotates" {
  command = plan

  assert {
    condition     = aws_kms_key.main.enable_key_rotation
    error_message = "The key must rotate."
  }

  assert {
    condition     = aws_kms_alias.main.name == "alias/sample-dev"
    error_message = "The alias should be the name of the stack."
  }
}

run "rejects_a_short_deletion_window" {
  command = plan

  variables {
    key_deletion_window_days = 1
  }

  expect_failures = [var.key_deletion_window_days]
}
{%- elif values.cloud == 'azure' %}
mock_provider "azurerm" {}

variables {
  name   = "sample-dev"
  region = "${{ values.region }}"
  tags = {
    environment = "dev"
  }
}

run "resource_group" {
  command = plan

  assert {
    condition     = azurerm_resource_group.main.name == "rg-sample-dev"
    error_message = "The resource group should be named after the stack."
  }

  assert {
    condition     = azurerm_resource_group.main.tags["environment"] == "dev"
    error_message = "The tags should be recorded on the resource group."
  }
}

run "rejects_an_invalid_name" {
  command = plan

  variables {
    name = "Sample_Dev"
  }

  expect_failures = [var.name]
}
{%- else %}
mock_provider "google" {}

override_data {
  target = data.google_storage_project_service_account.current
  values = {
    member = "serviceAccount:service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
  }
}

variables {
  name   = "sample-dev"
  region = "${{ values.region }}"
}

run "key_rotates" {
  command = plan

  assert {
    condition     = google_kms_crypto_key.logs.rotation_period == "7776000s"
    error_message = "The key should rotate every 90 days."
  }

  assert {
    condition     = google_kms_crypto_key_iam_member.storage.role == "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    error_message = "The Cloud Storage service agent must be allowed to use the key."
  }
}

run "rejects_an_invalid_name" {
  command = plan

  variables {
    name = "Sample_Dev"
  }

  expect_failures = [var.name]
}
{%- endif %}
