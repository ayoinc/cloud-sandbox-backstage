# =============================================================================
# GCP Cloud Run - Terraform Tests
# =============================================================================
# Uses Terraform native testing framework with output.* references.
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Mock Provider for Testing
# -----------------------------------------------------------------------------
mock_provider "google" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  name        = "test-cloudrun"
  environment = "dev"
  region      = "us-central1"
  project_id  = "test-project-123"
  owner       = "platform-team"

  # Container configuration
  container_image = ""
  image_tag       = "latest"
  container_port  = 8080

  # Resource configuration
  cpu               = "1"
  memory            = "512Mi"
  cpu_idle          = true
  startup_cpu_boost = true

  # Scaling configuration
  min_instances = 0
  max_instances = 10

  # Request configuration
  request_timeout       = 300
  execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

  # Ingress configuration
  ingress               = "INGRESS_TRAFFIC_ALL"
  allow_unauthenticated = true

  # Environment variables
  environment_variables = {
    LOG_LEVEL = "debug"
  }

  # Health checks
  health_check_path    = "/health"
  enable_startup_probe = true
  enable_liveness_probe = true

  # VPC configuration
  create_vpc_connector = false

  # Service account
  service_account_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]

  # Artifact Registry
  create_artifact_registry     = true
  artifact_registry_keep_count = 10

  # Monitoring
  enable_monitoring_alerts = true

  # Labels
  labels = {
    test-label = "test-value"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud Run Module Plan Succeeds
# -----------------------------------------------------------------------------
run "cloud_run_plan_succeeds" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.service_name != ""
    error_message = "Service name should not be empty"
  }

  assert {
    condition     = output.service_id != ""
    error_message = "Service ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud Run Naming Convention
# -----------------------------------------------------------------------------
run "cloud_run_naming_convention" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.service_name == "test-cloudrun-dev"
    error_message = "Service name should follow convention: {name}-{environment}"
  }
}

# -----------------------------------------------------------------------------
# Test: Service Account Created
# -----------------------------------------------------------------------------
run "service_account_created" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.service_account_email != ""
    error_message = "Service account email should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Artifact Registry Created When Enabled
# -----------------------------------------------------------------------------
run "artifact_registry_created_when_enabled" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    create_artifact_registry = true
  }

  assert {
    condition     = output.artifact_registry_id != null
    error_message = "Artifact Registry should be created when enabled"
  }

  assert {
    condition     = output.artifact_registry_url != null
    error_message = "Artifact Registry URL should not be null"
  }
}

# -----------------------------------------------------------------------------
# Test: Artifact Registry NOT Created When Disabled
# -----------------------------------------------------------------------------
run "artifact_registry_not_created_when_disabled" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    create_artifact_registry = false
    container_image          = "gcr.io/cloudrun/hello"
  }

  assert {
    condition     = output.artifact_registry_id == null
    error_message = "Artifact Registry should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# Test: VPC Connector NOT Created When Disabled
# -----------------------------------------------------------------------------
run "vpc_connector_not_created_when_disabled" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    create_vpc_connector = false
  }

  assert {
    condition     = output.vpc_connector_id == null
    error_message = "VPC connector should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud Run Info Summary
# -----------------------------------------------------------------------------
run "cloud_run_info_summary" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.cloud_run_info != null
    error_message = "Cloud Run info summary should not be null"
  }

  assert {
    condition     = output.cloud_run_info.location == "us-central1"
    error_message = "Cloud Run info location should match input"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment - Development
# -----------------------------------------------------------------------------
run "environment_dev" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    environment = "dev"
  }

  assert {
    condition     = output.service_name == "test-cloudrun-dev"
    error_message = "Development environment should be reflected in service name"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment - Production
# -----------------------------------------------------------------------------
run "environment_prod" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.service_name == "test-cloudrun-prod"
    error_message = "Production environment should be reflected in service name"
  }
}

# -----------------------------------------------------------------------------
# Test: Different Region
# -----------------------------------------------------------------------------
run "different_region" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    region = "europe-west1"
  }

  assert {
    condition     = output.service_location == "europe-west1"
    error_message = "Service should be created in the specified region"
  }
}

# -----------------------------------------------------------------------------
# Test: Docker Push Command
# -----------------------------------------------------------------------------
run "docker_push_command" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.docker_push_command != null
    error_message = "Docker push command should not be null"
  }

  assert {
    condition     = can(regex("docker push", output.docker_push_command))
    error_message = "Docker push command should contain docker push"
  }
}

# -----------------------------------------------------------------------------
# Test: Custom Labels
# -----------------------------------------------------------------------------
run "custom_labels" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    labels = {
      cost-center = "engineering"
      project     = "infrastructure"
    }
  }

  assert {
    condition     = output.cloud_run_info != null
    error_message = "Cloud Run service should be created with custom labels"
  }
}

# -----------------------------------------------------------------------------
# Test: Public Access Enabled
# -----------------------------------------------------------------------------
run "public_access_enabled" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    allow_unauthenticated = true
  }

  assert {
    condition     = output.cloud_run_info.allow_unauthenticated == true
    error_message = "Public access should be enabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Public Access Disabled
# -----------------------------------------------------------------------------
run "public_access_disabled" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    allow_unauthenticated = false
  }

  assert {
    condition     = output.cloud_run_info.allow_unauthenticated == false
    error_message = "Public access should be disabled"
  }
}
