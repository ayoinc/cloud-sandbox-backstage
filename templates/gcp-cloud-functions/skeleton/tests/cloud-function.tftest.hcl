# =============================================================================
# GCP Cloud Run Functions - Terraform Tests
# =============================================================================
# Run with: terraform test
# The provider is mocked: the tests need no Google Cloud account and create nothing.
# =============================================================================

mock_provider "google" {
  mock_resource "google_service_account" {
    defaults = {
      id     = "projects/test-project-123/serviceAccounts/mocked@test-project-123.iam.gserviceaccount.com"
      email  = "mocked@test-project-123.iam.gserviceaccount.com"
      member = "serviceAccount:mocked@test-project-123.iam.gserviceaccount.com"
    }
  }

  mock_resource "google_pubsub_topic" {
    defaults = {
      id = "projects/test-project-123/topics/test-dev"
    }
  }

  mock_resource "google_cloudfunctions2_function" {
    defaults = {
      id = "projects/test-project-123/locations/europe-west1/functions/test-dev"
    }
  }
}

variables {
  name        = "test"
  environment = "dev"
  project_id  = "test-project-123"
  region      = "europe-west1"
  description = "Test function"
  owner       = "group:default/platform-team"
  runtime     = "nodejs24"
}

run "creates_http_function" {
  command = apply

  assert {
    condition     = output.function_name == "test-dev"
    error_message = "The function must be named <name>-<environment>"
  }

  assert {
    condition     = output.source_bucket_name == "test-project-123-test-dev-src"
    error_message = "The source bucket must be named <project>-<name>-<environment>-src"
  }

  assert {
    condition     = output.trigger_topic_name == null
    error_message = "An HTTP function must have no trigger topic"
  }
}

run "secure_defaults" {
  command = plan

  module {
    source = "./modules/cloud-function"
  }

  assert {
    condition     = google_service_account.runtime.account_id == "run-test-dev" && google_service_account.build.account_id == "bld-test-dev"
    error_message = "The function must run and build as dedicated service accounts"
  }

  assert {
    condition     = length(google_project_iam_member.runtime) == 0
    error_message = "The runtime service account must start with no roles"
  }

  assert {
    condition     = length(google_cloud_run_service_iam_member.invoker) == 0
    error_message = "Nobody must be allowed to invoke the function unless listed"
  }

  assert {
    condition     = google_storage_bucket.source.uniform_bucket_level_access && google_storage_bucket.source.public_access_prevention == "enforced"
    error_message = "The source bucket must be private"
  }

  assert {
    condition     = google_cloudfunctions2_function.main.build_config[0].runtime == "nodejs24" && google_cloudfunctions2_function.main.build_config[0].entry_point == "handler"
    error_message = "The function must be built for the given runtime and entry point"
  }

  assert {
    condition     = google_cloudfunctions2_function.main.service_config[0].ingress_settings == "ALLOW_ALL" && length(google_cloudfunctions2_function.main.event_trigger) == 0
    error_message = "An HTTP function must be reachable, behind IAM, and have no event trigger"
  }

  assert {
    condition     = startswith(google_storage_bucket_object.source.name, "function-") && endswith(google_storage_bucket_object.source.name, ".zip")
    error_message = "The source object must be named after the hash of the source"
  }
}

run "http_function_with_invokers_and_secrets" {
  command = apply

  module {
    source = "./modules/cloud-function"
  }

  variables {
    allow_unauthenticated = true
    invokers              = ["serviceAccount:caller@test-project-123.iam.gserviceaccount.com"]
    secret_environment_variables = {
      API_KEY = { secret = "orders-api-key" }
    }
    runtime_service_account_roles = ["roles/datastore.user"]
  }

  assert {
    condition     = toset(keys(google_cloud_run_service_iam_member.invoker)) == toset(["allUsers", "serviceAccount:caller@test-project-123.iam.gserviceaccount.com"])
    error_message = "Listed invokers and allUsers must be bound to the service"
  }

  assert {
    condition     = google_secret_manager_secret_iam_member.runtime["API_KEY"].role == "roles/secretmanager.secretAccessor"
    error_message = "The runtime service account must be allowed to read the secret"
  }

  assert {
    condition     = google_cloudfunctions2_function.main.service_config[0].secret_environment_variables[0].version == "latest"
    error_message = "The secret must reach the function as an environment variable"
  }

  assert {
    condition     = google_project_iam_member.runtime["roles/datastore.user"].member == "serviceAccount:mocked@test-project-123.iam.gserviceaccount.com"
    error_message = "Listed roles must be granted to the runtime service account"
  }
}

run "pubsub_function" {
  command = apply

  module {
    source = "./modules/cloud-function"
  }

  variables {
    trigger_type = "pubsub"
  }

  assert {
    condition     = google_pubsub_topic.trigger[0].name == "test-dev"
    error_message = "A topic named after the function must be created"
  }

  assert {
    condition     = google_cloudfunctions2_function.main.event_trigger[0].event_type == "google.cloud.pubsub.topic.v1.messagePublished" && google_cloudfunctions2_function.main.event_trigger[0].retry_policy == "RETRY_POLICY_RETRY"
    error_message = "The function must be triggered by messages, with retries"
  }

  assert {
    condition     = google_cloudfunctions2_function.main.service_config[0].ingress_settings == "ALLOW_INTERNAL_ONLY"
    error_message = "A Pub/Sub function must not be reachable from the internet"
  }

  assert {
    condition     = google_cloud_run_service_iam_member.trigger[0].role == "roles/run.invoker" && length(google_cloud_run_service_iam_member.invoker) == 0
    error_message = "Only the trigger service account must be allowed to invoke the function"
  }
}

run "rejects_public_pubsub_function" {
  command = plan

  variables {
    trigger_type          = "pubsub"
    allow_unauthenticated = true
  }

  expect_failures = [var.allow_unauthenticated]
}
