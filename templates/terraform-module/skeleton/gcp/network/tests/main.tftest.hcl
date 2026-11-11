mock_provider "google" {}

variables {
  project_name = "acme-platform"
  environment  = "dev"
  project_id   = "acme-platform-dev"
  region       = "us-central1"
}

run "defaults" {
  command = plan

  assert {
    condition     = google_compute_network.main.name == "acme-platform-dev-vpc"
    error_message = "The VPC name must be derived from the project name and environment."
  }

  assert {
    condition     = google_compute_network.main.auto_create_subnetworks == false
    error_message = "The VPC must not create subnets automatically."
  }

  assert {
    condition     = google_compute_subnetwork.main["private"].ip_cidr_range == "10.2.0.0/20"
    error_message = "The private subnet must be the first /20 of the default range."
  }

  assert {
    condition     = google_compute_subnetwork.main["database"].ip_cidr_range == "10.2.32.0/20"
    error_message = "The database subnet must be the third /20 of the default range."
  }

  assert {
    condition     = alltrue([for subnet in google_compute_subnetwork.main : subnet.private_ip_google_access])
    error_message = "Every subnet must have Private Google Access."
  }

  assert {
    condition     = length(google_compute_subnetwork.main["private"].secondary_ip_range) == 2
    error_message = "The private subnet must carry the GKE pod and service ranges by default."
  }

  assert {
    condition     = output.subnet_names == ["acme-platform-dev-private", "acme-platform-dev-public", "acme-platform-dev-database"]
    error_message = "subnet_names must list the private subnet first."
  }

  assert {
    condition     = length(google_compute_router_nat.main) == 1 && google_compute_router_nat.main[0].nat_ip_allocate_option == "AUTO_ONLY"
    error_message = "Cloud NAT must be created with automatic addresses by default."
  }

  assert {
    condition     = length(google_compute_firewall.allow_web) == 0
    error_message = "No web ingress rule may exist without source ranges."
  }

  assert {
    condition     = length(google_service_networking_connection.private_service_access) == 1
    error_message = "Private service access must be enabled by default."
  }

  assert {
    condition     = output.private_ip_range == "acme-platform-dev-psa"
    error_message = "private_ip_range must be the name of the reserved range."
  }

  assert {
    condition     = length(google_dns_managed_zone.private) == 0 && length(google_compute_shared_vpc_host_project.main) == 0
    error_message = "Private DNS and Shared VPC must be off by default."
  }
}

run "minimal" {
  command = plan

  variables {
    enable_nat                    = false
    enable_private_service_access = false
    enable_gke_secondary_ranges   = false
    enable_iap_ssh                = false
    enable_flow_logs              = false
  }

  assert {
    condition     = length(google_compute_router.main) == 0 && length(google_compute_router_nat.main) == 0
    error_message = "Disabling NAT must remove the router and the gateway."
  }

  assert {
    condition     = output.private_ip_range == null
    error_message = "private_ip_range must be null without private service access."
  }

  assert {
    condition     = length(google_compute_subnetwork.main["private"].secondary_ip_range) == 0
    error_message = "No secondary ranges may exist when they are disabled."
  }

  assert {
    condition     = length(google_compute_subnetwork.main["private"].log_config) == 0
    error_message = "Flow logs must be off when disabled."
  }

  assert {
    condition     = length(google_compute_firewall.allow_iap_ssh) == 0
    error_message = "The IAP SSH rule must not exist when disabled."
  }
}

run "all_features" {
  command = plan

  variables {
    network_cidr           = "10.50.0.0/20"
    nat_ip_count           = 2
    web_source_ranges      = ["203.0.113.0/24"]
    enable_private_dns     = true
    private_dns_domain     = "internal.acme.example."
    enable_shared_vpc_host = true
    routing_mode           = "GLOBAL"
  }

  assert {
    condition     = google_compute_subnetwork.main["public"].ip_cidr_range == "10.50.1.0/24"
    error_message = "Subnets must follow network_cidr."
  }

  assert {
    condition     = length(google_compute_address.nat) == 2 && google_compute_router_nat.main[0].nat_ip_allocate_option == "MANUAL_ONLY"
    error_message = "Static NAT addresses must switch the gateway to manual allocation."
  }

  assert {
    condition     = google_compute_firewall.allow_web[0].source_ranges == toset(["203.0.113.0/24"])
    error_message = "The web rule must use the configured source ranges."
  }

  assert {
    condition     = google_dns_managed_zone.private[0].dns_name == "internal.acme.example." && google_dns_managed_zone.private[0].visibility == "private"
    error_message = "The DNS zone must be private and use the configured domain."
  }

  assert {
    condition     = length(google_compute_shared_vpc_host_project.main) == 1
    error_message = "The Shared VPC host resource must be created when enabled."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    network_cidr = "not-a-cidr"
  }

  expect_failures = [var.network_cidr]
}
