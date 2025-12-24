# =============================================================================
# GCP VPC - Terraform Tests
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

mock_provider "google-beta" {
  alias = "mock-beta"
}

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  name                 = "test-vpc"
  environment          = "dev"
  region               = "us-central1"
  description          = "Test VPC for validation"
  owner                = "platform-team"
  address_space        = "10.0.0.0/16"
  public_subnet_cidr   = "10.0.1.0/24"
  private_subnet_cidr  = "10.0.2.0/24"
  database_subnet_cidr = "10.0.3.0/24"
  gke_subnet_cidr      = "10.0.16.0/20"
  gke_pods_cidr        = "10.100.0.0/16"
  gke_services_cidr    = "10.101.0.0/20"
  enable_nat           = true
  enable_flow_logs     = true
  labels = {
    test-label = "test-value"
  }
}

# -----------------------------------------------------------------------------
# Test: VPC Module Plan Succeeds
# -----------------------------------------------------------------------------
run "vpc_plan_succeeds" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  assert {
    condition     = output.vpc_name != ""
    error_message = "VPC name should not be empty"
  }

  assert {
    condition     = output.vpc_id != ""
    error_message = "VPC ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: VPC Naming Convention
# -----------------------------------------------------------------------------
run "vpc_naming_convention" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  assert {
    condition     = output.vpc_name == "vpc-test-vpc-dev"
    error_message = "VPC name should follow convention: vpc-{name}-{environment}"
  }
}

# -----------------------------------------------------------------------------
# Test: Subnet IDs are Created
# -----------------------------------------------------------------------------
run "subnet_ids_created" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  assert {
    condition     = output.public_subnet_id != ""
    error_message = "Public subnet ID should not be empty"
  }

  assert {
    condition     = output.private_subnet_id != ""
    error_message = "Private subnet ID should not be empty"
  }

  assert {
    condition     = output.database_subnet_id != ""
    error_message = "Database subnet ID should not be empty"
  }

  assert {
    condition     = output.gke_subnet_id != ""
    error_message = "GKE subnet ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Subnet Names Follow Convention
# -----------------------------------------------------------------------------
run "subnet_naming_convention" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  assert {
    condition     = output.public_subnet_name == "subnet-test-vpc-public-dev"
    error_message = "Public subnet name should follow convention"
  }

  assert {
    condition     = output.private_subnet_name == "subnet-test-vpc-private-dev"
    error_message = "Private subnet name should follow convention"
  }
}

# -----------------------------------------------------------------------------
# Test: GKE Secondary Ranges
# -----------------------------------------------------------------------------
run "gke_secondary_ranges" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  assert {
    condition     = output.gke_pods_range_name == "pods"
    error_message = "GKE pods range name should be 'pods'"
  }

  assert {
    condition     = output.gke_services_range_name == "services"
    error_message = "GKE services range name should be 'services'"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud Router Created
# -----------------------------------------------------------------------------
run "cloud_router_created" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  assert {
    condition     = output.router_id != ""
    error_message = "Cloud Router ID should not be empty"
  }

  assert {
    condition     = output.router_name == "router-test-vpc-dev"
    error_message = "Cloud Router name should follow convention"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud NAT Created When Enabled
# -----------------------------------------------------------------------------
run "cloud_nat_created_when_enabled" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  variables {
    enable_nat = true
  }

  assert {
    condition     = output.nat_id != null
    error_message = "Cloud NAT should be created when enable_nat is true"
  }

  assert {
    condition     = output.nat_name == "nat-test-vpc-dev"
    error_message = "Cloud NAT name should follow convention"
  }
}

# -----------------------------------------------------------------------------
# Test: Cloud NAT NOT Created When Disabled
# -----------------------------------------------------------------------------
run "cloud_nat_not_created_when_disabled" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  variables {
    enable_nat = false
  }

  assert {
    condition     = output.nat_id == null
    error_message = "Cloud NAT should not be created when enable_nat is false"
  }
}

# -----------------------------------------------------------------------------
# Test: Subnet Map Contains All Subnets
# -----------------------------------------------------------------------------
run "subnet_map_complete" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  assert {
    condition     = length(output.subnet_ids) == 4
    error_message = "Subnet IDs map should contain 4 subnets"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "public")
    error_message = "Subnet IDs map should contain 'public' key"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "private")
    error_message = "Subnet IDs map should contain 'private' key"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "database")
    error_message = "Subnet IDs map should contain 'database' key"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "gke")
    error_message = "Subnet IDs map should contain 'gke' key"
  }
}

# -----------------------------------------------------------------------------
# Test: VPC Info Summary
# -----------------------------------------------------------------------------
run "vpc_info_summary" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  assert {
    condition     = output.vpc_info != null
    error_message = "VPC info summary should not be null"
  }

  assert {
    condition     = output.vpc_info.name == "vpc-test-vpc-dev"
    error_message = "VPC info name should match expected naming"
  }

  assert {
    condition     = output.vpc_info.region == "us-central1"
    error_message = "VPC info region should match input"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment Validation - Development
# -----------------------------------------------------------------------------
run "environment_dev" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  variables {
    environment = "dev"
  }

  assert {
    condition     = output.vpc_name == "vpc-test-vpc-dev"
    error_message = "Development environment should be reflected in VPC name"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment Validation - Production
# -----------------------------------------------------------------------------
run "environment_prod" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.vpc_name == "vpc-test-vpc-prod"
    error_message = "Production environment should be reflected in VPC name"
  }
}

# -----------------------------------------------------------------------------
# Test: Different Region
# -----------------------------------------------------------------------------
run "different_region" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  variables {
    region = "europe-west1"
  }

  assert {
    condition     = output.vpc_info.region == "europe-west1"
    error_message = "VPC should be created in the specified region"
  }
}

# -----------------------------------------------------------------------------
# Test: Custom Labels
# -----------------------------------------------------------------------------
run "custom_labels" {
  command = plan

  providers = {
    google      = google.mock
    google-beta = google-beta.mock-beta
  }

  variables {
    labels = {
      cost-center = "engineering"
      project     = "infrastructure"
    }
  }

  assert {
    condition     = output.vpc_info != null
    error_message = "VPC should be created with custom labels"
  }
}
