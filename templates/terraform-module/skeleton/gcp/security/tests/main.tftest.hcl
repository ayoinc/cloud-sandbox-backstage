mock_provider "google" {}
mock_provider "random" {}

variables {
  project_name = "acme-platform"
  environment  = "dev"
  project_id   = "acme-platform-dev"
  region       = "us-central1"
}

run "defaults" {
  command = plan

  assert {
    condition     = google_kms_crypto_key.main.name == "acme-platform-dev-key"
    error_message = "The key name must be derived from the project name and environment."
  }

  assert {
    condition     = google_kms_crypto_key.main.rotation_period == "7776000s"
    error_message = "The key must rotate every 90 days by default."
  }

  assert {
    condition     = google_kms_crypto_key.main.version_template[0].protection_level == "SOFTWARE"
    error_message = "The key must use software protection by default."
  }

  assert {
    condition     = google_kms_key_ring.main.location == "us-central1"
    error_message = "The key ring must be created in the configured region."
  }

  assert {
    condition     = google_service_account.application.account_id == "acme-platform-dev-app"
    error_message = "The service account ID must be derived from the project name and environment."
  }

  assert {
    condition     = length(google_project_iam_member.application) == 2
    error_message = "The service account must get the two default roles."
  }

  assert {
    condition     = length(google_kms_crypto_key_iam_member.storage_service_agent) == 1
    error_message = "The storage service agent must be granted access to the key by default."
  }

  assert {
    condition     = length(google_secret_manager_secret.main) == 0
    error_message = "No secrets may be created by default."
  }

  assert {
    condition     = length(google_project_iam_audit_config.all_services) == 1
    error_message = "Audit logs must be enabled by default."
  }

  assert {
    condition     = length(output.org_policy_names) == 0
    error_message = "Organization policies must be off by default."
  }
}

run "long_project_name" {
  command = plan

  variables {
    project_name = "a-very-long-terraform-module-name"
    environment  = "staging"
  }

  assert {
    condition     = google_service_account.application.account_id == "a-very-long-terr-staging-app"
    error_message = "Long project names must be shortened so the account ID fits in 30 characters."
  }
}

run "secrets" {
  command = plan

  variables {
    secret_names     = ["database-url", "api-token"]
    secret_accessors = ["group:platform-oncall@acme.example"]
  }

  assert {
    condition     = google_secret_manager_secret.main["database-url"].secret_id == "acme-platform-dev-database-url"
    error_message = "Secret IDs must be prefixed with the project name and environment."
  }

  assert {
    condition     = google_secret_manager_secret.main["api-token"].replication[0].user_managed[0].replicas[0].location == "us-central1"
    error_message = "Secrets must be replicated only to the configured region."
  }

  assert {
    condition     = length(google_secret_manager_secret_iam_member.application) == 2 && length(google_secret_manager_secret_iam_member.accessors) == 2
    error_message = "The application and every accessor must be able to read each secret."
  }
}

run "org_policies_and_hsm" {
  command = plan

  variables {
    kms_key_protection_level      = "HSM"
    kms_encrypter_decrypters      = ["serviceAccount:pipeline@acme-platform-dev.iam.gserviceaccount.com"]
    grant_storage_service_agent   = false
    enable_audit_logs             = false
    enable_org_policies           = true
    allowed_policy_member_domains = ["C01abc234"]
  }

  assert {
    condition     = google_kms_crypto_key.main.version_template[0].protection_level == "HSM"
    error_message = "The protection level must follow kms_key_protection_level."
  }

  assert {
    condition     = length(google_kms_crypto_key_iam_member.encrypter_decrypters) == 1 && length(google_kms_crypto_key_iam_member.storage_service_agent) == 0
    error_message = "Key access must follow the configured members."
  }

  assert {
    condition     = google_org_policy_policy.require_os_login[0].name == "projects/acme-platform-dev/policies/compute.requireOsLogin"
    error_message = "The OS Login policy must target the project."
  }

  assert {
    condition     = length(google_org_policy_policy.restrict_vm_external_ips) == 1 && length(google_org_policy_policy.allowed_policy_member_domains) == 1
    error_message = "All three organization policies must be created."
  }

  assert {
    condition     = length(google_project_iam_audit_config.all_services) == 0
    error_message = "Audit logs must be removed when disabled."
  }
}

run "rejects_public_members" {
  command = plan

  variables {
    kms_encrypter_decrypters = ["allUsers"]
  }

  expect_failures = [var.kms_encrypter_decrypters]
}

run "rejects_basic_roles" {
  command = plan

  variables {
    service_account_roles = ["roles/editor"]
  }

  expect_failures = [var.service_account_roles]
}

run "rejects_slow_rotation" {
  command = plan

  variables {
    kms_key_rotation_period = "31536000s"
  }

  expect_failures = [var.kms_key_rotation_period]
}
