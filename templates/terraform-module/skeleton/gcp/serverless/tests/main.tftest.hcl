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
    condition     = length(google_cloud_run_v2_service.main) == 1 && length(google_cloudfunctions2_function.main) == 0
    error_message = "A Cloud Run service must be deployed by default."
  }

  assert {
    condition     = google_cloud_run_v2_service.main[0].name == "acme-platform-dev-api" && google_cloud_run_v2_service.main[0].location == "us-central1"
    error_message = "The service must be named after the project, environment and service name."
  }

  assert {
    condition     = google_cloud_run_v2_service.main[0].template[0].containers[0].image == "us-docker.pkg.dev/cloudrun/container/hello"
    error_message = "The sample image must be deployed by default."
  }

  assert {
    condition     = google_cloud_run_v2_service.main[0].template[0].containers[0].resources[0].limits["memory"] == "512Mi"
    error_message = "The default memory limit must be 512Mi."
  }

  assert {
    condition     = google_cloud_run_v2_service.main[0].template[0].scaling[0].min_instance_count == 0 && google_cloud_run_v2_service.main[0].template[0].scaling[0].max_instance_count == 10
    error_message = "The service must scale from 0 to 10 instances by default."
  }

  assert {
    condition     = google_cloud_run_v2_service.main[0].ingress == "INGRESS_TRAFFIC_ALL"
    error_message = "The ingress setting must be translated for Cloud Run."
  }

  assert {
    condition     = google_service_account.runtime.account_id == "acme-platform-dev-run"
    error_message = "The service must run as a dedicated service account."
  }

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.invokers) == 0
    error_message = "Nobody may call the service by default."
  }

  assert {
    condition     = length(google_storage_bucket.function_source) == 0 && length(google_pubsub_topic.main) == 0 && length(google_cloud_scheduler_job.main) == 0 && length(google_service_account.invoker) == 0
    error_message = "Function source, Pub/Sub and scheduling must be off by default."
  }
}

run "null_optional_inputs" {
  command = plan

  variables {
    health_check_path   = null
    source_archive_path = null
    vpc_connector       = null
    kms_key_id          = null
    schedule_cron       = null
  }

  assert {
    condition     = length(google_cloud_run_v2_service.main[0].template[0].vpc_access) == 0 && length(google_cloud_run_v2_service.main[0].template[0].containers[0].liveness_probe) == 0
    error_message = "Null inputs must leave the VPC connector and liveness probe unset."
  }
}

run "cloud_run_all_features" {
  command = plan

  variables {
    service_name                 = "orders"
    container_image              = "us-central1-docker.pkg.dev/acme-platform-dev/images/orders:1.4.2"
    health_check_path            = "/healthz"
    cpu_idle                     = false
    memory                       = "1Gi"
    cpu                          = "2"
    min_instances                = 1
    environment_variables        = { LOG_LEVEL = "info" }
    secret_environment_variables = { DATABASE_URL = { secret = "acme-platform-dev-database-url" } }
    vpc_connector                = "projects/acme-platform-dev/locations/us-central1/connectors/acme-dev"
    ingress                      = "internal-and-cloud-load-balancing"
    allow_unauthenticated        = true
    invoker_members              = ["group:orders-clients@acme.example"]
    kms_key_id                   = "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    enable_pubsub                = true
    schedule_cron                = "0 6 * * *"
    schedule_time_zone           = "Europe/London"
  }

  assert {
    condition     = google_cloud_run_v2_service.main[0].name == "acme-platform-dev-orders" && google_cloud_run_v2_service.main[0].ingress == "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    error_message = "Name and ingress must follow the inputs."
  }

  assert {
    condition     = google_cloud_run_v2_service.main[0].template[0].containers[0].liveness_probe[0].http_get[0].path == "/healthz"
    error_message = "The liveness probe must use the configured path."
  }

  assert {
    condition     = length(google_cloud_run_v2_service.main[0].template[0].containers[0].env) == 2
    error_message = "Plain and secret environment variables must both be set."
  }

  assert {
    condition     = google_cloud_run_v2_service.main[0].template[0].vpc_access[0].egress == "PRIVATE_RANGES_ONLY"
    error_message = "The VPC connector must route private ranges only by default."
  }

  assert {
    condition     = google_secret_manager_secret_iam_member.runtime["DATABASE_URL"].secret_id == "acme-platform-dev-database-url"
    error_message = "The runtime service account must be able to read referenced secrets."
  }

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.invokers) == 2 && google_cloud_run_v2_service_iam_member.invokers["allUsers"].role == "roles/run.invoker"
    error_message = "Public access and the listed members must be granted the invoker role."
  }

  assert {
    condition     = google_service_account.invoker[0].account_id == "acme-platform-dev-call" && length(google_cloud_run_v2_service_iam_member.invoker_service_account) == 1
    error_message = "Triggers must call the service with a dedicated invoker account."
  }

  assert {
    condition     = google_pubsub_topic.main[0].name == "acme-platform-dev-orders-events" && google_pubsub_topic.main[0].kms_key_name == "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    error_message = "The topic must be named after the service and encrypted with the given key."
  }

  assert {
    condition     = google_pubsub_subscription.push[0].ack_deadline_seconds == 60
    error_message = "The push subscription must use the default acknowledgement deadline."
  }

  assert {
    condition     = google_cloud_scheduler_job.main[0].schedule == "0 6 * * *" && google_cloud_scheduler_job.main[0].time_zone == "Europe/London"
    error_message = "The schedule must follow the inputs."
  }
}

run "cloud_function" {
  command = plan

  variables {
    deploy_type                  = "function"
    source_archive_path          = "function-source.zip"
    runtime                      = "nodejs22"
    entry_point                  = "handler"
    ingress                      = "internal"
    environment_variables        = { LOG_LEVEL = "info" }
    secret_environment_variables = { API_TOKEN = { secret = "acme-platform-dev-api-token", version = "3" } }
    vpc_connector                = "projects/acme-platform-dev/locations/us-central1/connectors/acme-dev"
    invoker_members              = ["serviceAccount:caller@acme-platform-dev.iam.gserviceaccount.com"]
  }

  assert {
    condition     = length(google_cloudfunctions2_function.main) == 1 && length(google_cloud_run_v2_service.main) == 0
    error_message = "Only a Cloud Function must be deployed."
  }

  assert {
    condition     = google_cloudfunctions2_function.main[0].build_config[0].runtime == "nodejs22" && google_cloudfunctions2_function.main[0].build_config[0].entry_point == "handler"
    error_message = "Runtime and entry point must follow the inputs."
  }

  assert {
    condition     = google_cloudfunctions2_function.main[0].service_config[0].ingress_settings == "ALLOW_INTERNAL_ONLY"
    error_message = "The ingress setting must be translated for Cloud Functions."
  }

  assert {
    condition     = google_cloudfunctions2_function.main[0].service_config[0].available_memory == "512Mi" && google_cloudfunctions2_function.main[0].service_config[0].max_instance_count == 10
    error_message = "Shared sizing defaults must apply to functions."
  }

  assert {
    condition     = google_cloudfunctions2_function.main[0].service_config[0].secret_environment_variables[0].version == "3"
    error_message = "Secret environment variables must reference the requested version."
  }

  assert {
    condition     = google_cloudfunctions2_function.main[0].service_config[0].vpc_connector_egress_settings == "PRIVATE_RANGES_ONLY"
    error_message = "The VPC egress setting must be applied to the function."
  }

  assert {
    condition     = google_storage_bucket.function_source[0].public_access_prevention == "enforced" && google_storage_bucket_object.function_source[0].source == "function-source.zip"
    error_message = "The source archive must be uploaded to a private bucket."
  }

  assert {
    condition     = one(values(google_cloud_run_v2_service_iam_member.invokers)).name == "acme-platform-dev-api"
    error_message = "Invokers must be granted on the service behind the function."
  }
}

run "rejects_function_without_source" {
  command = plan

  variables {
    deploy_type = "function"
  }

  expect_failures = [google_storage_bucket_object.function_source]
}

run "rejects_public_member_in_list" {
  command = plan

  variables {
    invoker_members = ["allUsers"]
  }

  expect_failures = [var.invoker_members]
}
