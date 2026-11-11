mock_provider "google" {}

variables {
  project_name = "acme-platform"
  environment  = "dev"
  project_id   = "acme-platform-dev"
  region       = "us-central1"
  zone         = "us-central1-a"
}

run "defaults" {
  command = plan

  assert {
    condition     = google_service_account.compute.account_id == "acme-platform-dev-vm"
    error_message = "The service account ID must be derived from the project name and environment."
  }

  assert {
    condition     = google_compute_instance_template.main.machine_type == "e2-medium"
    error_message = "The default machine type must be e2-medium."
  }

  assert {
    condition     = google_compute_instance_template.main.network_interface[0].network == "default"
    error_message = "Without a network the instances must attach to the default network."
  }

  assert {
    condition     = length(google_compute_instance_template.main.network_interface[0].access_config) == 0
    error_message = "Instances must not get an external address."
  }

  assert {
    condition     = google_compute_instance_template.main.shielded_instance_config[0].enable_secure_boot == true
    error_message = "Secure boot must be enabled."
  }

  assert {
    condition     = google_compute_instance_template.main.metadata["enable-oslogin"] == "TRUE" && google_compute_instance_template.main.metadata["block-project-ssh-keys"] == "true"
    error_message = "OS Login must be enabled and project SSH keys blocked."
  }

  assert {
    condition     = strcontains(google_compute_instance_template.main.metadata["startup-script"], "listen 80 default_server")
    error_message = "The bundled startup script must configure nginx on the application port."
  }

  assert {
    condition     = google_compute_instance_template.main.scheduling[0].provisioning_model == "STANDARD"
    error_message = "Instances must be standard VMs by default."
  }

  assert {
    condition     = length(google_compute_instance_template.main.disk) == 1
    error_message = "Only the boot disk may be attached by default."
  }

  assert {
    condition     = google_compute_health_check.main.http_health_check[0].request_path == "/healthz" && google_compute_health_check.main.http_health_check[0].port == 80
    error_message = "The default health check must probe /healthz on port 80."
  }

  assert {
    condition     = google_compute_region_instance_group_manager.main.distribution_policy_zones == toset(["us-central1-a"])
    error_message = "The group must run in the primary zone by default."
  }

  assert {
    condition     = google_compute_region_autoscaler.main.autoscaling_policy[0].min_replicas == 1 && google_compute_region_autoscaler.main.autoscaling_policy[0].max_replicas == 3
    error_message = "The autoscaler must default to 1-3 replicas."
  }

  assert {
    condition     = length(google_compute_firewall.iap_ssh) == 1 && length(google_compute_firewall.app) == 0
    error_message = "IAP SSH must be allowed and no application ingress rule created by default."
  }

  assert {
    condition     = google_compute_firewall.health_check.network == "default"
    error_message = "Firewall rules must be created in the instance network."
  }
}

run "null_network_inputs" {
  command = plan

  variables {
    network_name      = null
    subnet_name       = null
    kms_key_id        = null
    startup_script    = null
    health_check_path = null
  }

  assert {
    condition     = google_compute_instance_template.main.network_interface[0].network == "default"
    error_message = "A null network must fall back to the default network."
  }

  assert {
    condition     = length(google_compute_health_check.main.tcp_health_check) == 1 && length(google_compute_health_check.main.http_health_check) == 0
    error_message = "A null health check path must switch to a TCP check."
  }
}

run "all_features" {
  command = plan

  variables {
    additional_zones      = ["us-central1-b", "us-central1-c"]
    network_name          = "acme-platform-dev-vpc"
    subnet_name           = "acme-platform-dev-private"
    data_disk_size_gb     = 50
    kms_key_id            = "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    enable_spot           = true
    metadata              = { app-version = "1.4.2" }
    startup_script        = "#!/bin/bash\necho custom"
    app_port              = 8080
    min_replicas          = 2
    max_replicas          = 6
    enable_iap_ssh        = false
    app_source_ranges     = ["10.2.16.0/20"]
    service_account_roles = ["roles/logging.logWriter"]
  }

  assert {
    condition     = google_compute_instance_template.main.network_interface[0].subnetwork == "acme-platform-dev-private" && google_compute_instance_template.main.network_interface[0].subnetwork_project == "acme-platform-dev"
    error_message = "Instances must attach to the given subnet."
  }

  assert {
    condition     = length(google_compute_instance_template.main.disk) == 2
    error_message = "The data disk must be attached."
  }

  assert {
    condition     = alltrue([for d in google_compute_instance_template.main.disk : d.disk_encryption_key[0].kms_key_self_link == "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"])
    error_message = "Every disk must be encrypted with the given key."
  }

  assert {
    condition     = google_compute_instance_template.main.scheduling[0].provisioning_model == "SPOT" && google_compute_instance_template.main.scheduling[0].automatic_restart == false
    error_message = "Spot scheduling must be configured."
  }

  assert {
    condition     = google_compute_instance_template.main.metadata["startup-script"] == "#!/bin/bash\necho custom" && google_compute_instance_template.main.metadata["app-version"] == "1.4.2"
    error_message = "Custom startup script and metadata must be passed through."
  }

  assert {
    condition     = length(google_compute_region_instance_group_manager.main.distribution_policy_zones) == 3 && google_compute_region_instance_group_manager.main.update_policy[0].max_surge_fixed == 3
    error_message = "The group must span three zones and surge one instance per zone."
  }

  assert {
    condition     = google_compute_firewall.app[0].network == "acme-platform-dev-vpc" && google_compute_firewall.app[0].source_ranges == toset(["10.2.16.0/20"])
    error_message = "The application rule must use the given network and ranges."
  }

  assert {
    condition     = length(google_compute_firewall.iap_ssh) == 0 && length(google_project_iam_member.compute) == 1
    error_message = "IAP SSH must be removable and roles must follow the input."
  }
}

run "rejects_inverted_replicas" {
  command = plan

  variables {
    min_replicas = 5
    max_replicas = 2
  }

  expect_failures = [google_compute_region_autoscaler.main]
}

run "rejects_open_ingress" {
  command = plan

  variables {
    app_source_ranges = ["0.0.0.0/0"]
  }

  expect_failures = [var.app_source_ranges]
}
