# =============================================================================
# GCP Cloud SQL - Terraform Tests
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

mock_provider "random" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  name             = "test-cloudsql"
  environment      = "dev"
  region           = "us-central1"
  project_id       = "test-project-123"
  database_version = "POSTGRES_15"
  owner            = "platform-team"

  # Instance configuration
  tier                = "db-f1-micro"
  availability_type   = "ZONAL"
  disk_size           = 10
  disk_type           = "PD_SSD"
  disk_autoresize     = true
  activation_policy   = "ALWAYS"
  deletion_protection = false

  # Database configuration
  database_name            = ""
  db_user_name             = "app_user"
  database_deletion_policy = "DELETE"
  user_deletion_policy     = "DELETE"
  database_flags           = []

  # Network configuration
  enable_private_ip   = false
  enable_public_ip    = true
  network_id          = ""
  require_ssl         = true
  authorized_networks = []

  # Backup configuration
  enable_backups                 = true
  backup_start_time              = "03:00"
  backup_location                = null
  backup_retention_days          = 7
  enable_point_in_time_recovery  = true
  transaction_log_retention_days = 7

  # Maintenance configuration
  maintenance_window_day   = 7
  maintenance_window_hour  = 3
  maintenance_update_track = "stable"

  # Query Insights
  enable_query_insights                  = true
  query_insights_string_length           = 1024
  query_insights_record_application_tags = true
  query_insights_record_client_address   = true

  # Secret Manager
  store_password_in_secret_manager = true

  # SSL
  create_ssl_certificate = false

  # Labels
  labels = {
    test-label = "test-value"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud SQL Module Plan Succeeds
# -----------------------------------------------------------------------------
run "cloud_sql_plan_succeeds" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  assert {
    condition     = output.instance_name != ""
    error_message = "Instance name should not be empty"
  }

  assert {
    condition     = output.connection_name != ""
    error_message = "Connection name should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud SQL Naming Convention
# -----------------------------------------------------------------------------
run "cloud_sql_naming_convention" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  assert {
    condition     = output.instance_name == "test-cloudsql-dev"
    error_message = "Instance name should follow convention: {name}-{environment}"
  }
}

# -----------------------------------------------------------------------------
# Test: Database Created
# -----------------------------------------------------------------------------
run "database_created" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  assert {
    condition     = output.database_name != ""
    error_message = "Database name should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: User Created
# -----------------------------------------------------------------------------
run "user_created" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  assert {
    condition     = output.user_name == "app_user"
    error_message = "User name should be 'app_user'"
  }
}

# -----------------------------------------------------------------------------
# Test: Password Secret Created When Enabled
# -----------------------------------------------------------------------------
run "password_secret_created_when_enabled" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  variables {
    store_password_in_secret_manager = true
  }

  assert {
    condition     = output.password_secret_id != null
    error_message = "Password secret should be created when enabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud SQL Info Summary
# -----------------------------------------------------------------------------
run "cloud_sql_info_summary" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  assert {
    condition     = output.cloud_sql_info != null
    error_message = "Cloud SQL info summary should not be null"
  }

  assert {
    condition     = output.cloud_sql_info.region == "us-central1"
    error_message = "Cloud SQL info region should match input"
  }

  assert {
    condition     = output.cloud_sql_info.database_version == "POSTGRES_15"
    error_message = "Cloud SQL info database version should match input"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment - Development
# -----------------------------------------------------------------------------
run "environment_dev" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  variables {
    environment = "dev"
  }

  assert {
    condition     = output.instance_name == "test-cloudsql-dev"
    error_message = "Development environment should be reflected in instance name"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment - Production
# -----------------------------------------------------------------------------
run "environment_prod" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.instance_name == "test-cloudsql-prod"
    error_message = "Production environment should be reflected in instance name"
  }
}

# -----------------------------------------------------------------------------
# Test: Different Region
# -----------------------------------------------------------------------------
run "different_region" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  variables {
    region = "europe-west1"
  }

  assert {
    condition     = output.cloud_sql_info.region == "europe-west1"
    error_message = "Instance should be created in the specified region"
  }
}

# -----------------------------------------------------------------------------
# Test: MySQL Database Version
# -----------------------------------------------------------------------------
run "mysql_database_version" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  variables {
    database_version = "MYSQL_8_0"
  }

  assert {
    condition     = output.cloud_sql_info.database_version == "MYSQL_8_0"
    error_message = "MySQL database version should be set correctly"
  }
}

# -----------------------------------------------------------------------------
# Test: High Availability Configuration
# -----------------------------------------------------------------------------
run "high_availability_configuration" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  variables {
    availability_type = "REGIONAL"
  }

  assert {
    condition     = output.cloud_sql_info.availability_type == "REGIONAL"
    error_message = "High availability should be enabled with REGIONAL availability type"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud SQL Proxy Command
# -----------------------------------------------------------------------------
run "cloud_sql_proxy_command" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  assert {
    condition     = output.cloud_sql_proxy_command != null
    error_message = "Cloud SQL Proxy command should not be null"
  }

  assert {
    condition     = can(regex("cloud-sql-proxy", output.cloud_sql_proxy_command))
    error_message = "Cloud SQL Proxy command should contain cloud-sql-proxy"
  }
}

# -----------------------------------------------------------------------------
# Test: Backup Configuration
# -----------------------------------------------------------------------------
run "backup_configuration" {
  command = plan

  providers = {
    google = google.mock
    random = random.mock
  }

  variables {
    enable_backups        = true
    backup_retention_days = 14
  }

  assert {
    condition     = output.cloud_sql_info.backups_enabled == true
    error_message = "Backups should be enabled"
  }

  assert {
    condition     = output.cloud_sql_info.backup_retention_days == 14
    error_message = "Backup retention should be 14 days"
  }
}
