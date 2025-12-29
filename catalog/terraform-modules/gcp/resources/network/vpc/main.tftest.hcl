# Terraform native tests for GCP VPC module

variables {
  project_name = "test-project"
  project_id   = "my-gcp-project"
  environment  = "test"
  region       = "us-central1"

  subnets = [
    {
      name          = "subnet-1"
      ip_cidr_range = "10.0.1.0/24"
      region        = "us-central1"
    }
  ]

  labels = {
    test = "true"
  }
}

run "vpc_creation" {
  command = plan

  assert {
    condition     = google_compute_network.main.auto_create_subnetworks == false
    error_message = "Auto create subnetworks should be disabled"
  }
}

run "subnet_creation" {
  command = plan

  assert {
    condition     = length(google_compute_subnetwork.main) == 1
    error_message = "Should create 1 subnet"
  }
}

run "private_google_access" {
  command = plan

  assert {
    condition     = google_compute_subnetwork.main["subnet-1"].private_ip_google_access == true
    error_message = "Private Google access should be enabled"
  }
}
