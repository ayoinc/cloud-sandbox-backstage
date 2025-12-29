terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_compute_router_nat" "nat" {
  project = var.project_id
  region  = var.region
  name    = var.nat_name
  router  = var.router_name

  nat_ip_allocate_option             = var.nat_ip_allocate_option
  nat_ips                            = var.nat_ip_allocate_option == "MANUAL_ONLY" ? var.nat_ips : null
  source_subnetwork_ip_ranges_to_nat = var.source_subnetwork_ip_ranges_to_nat

  dynamic "subnetwork" {
    for_each = var.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS" ? var.subnetworks : []
    content {
      name                     = subnetwork.value.name
      source_ip_ranges_to_nat  = subnetwork.value.source_ip_ranges_to_nat
      secondary_ip_range_names = lookup(subnetwork.value, "secondary_ip_range_names", null)
    }
  }

  min_ports_per_vm                    = var.min_ports_per_vm
  max_ports_per_vm                    = var.enable_dynamic_port_allocation ? var.max_ports_per_vm : null
  enable_dynamic_port_allocation      = var.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = var.enable_endpoint_independent_mapping

  udp_idle_timeout_sec             = var.udp_idle_timeout_sec
  tcp_established_idle_timeout_sec = var.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec  = var.tcp_transitory_idle_timeout_sec
  tcp_time_wait_timeout_sec        = var.tcp_time_wait_timeout_sec
  icmp_idle_timeout_sec            = var.icmp_idle_timeout_sec

  dynamic "log_config" {
    for_each = var.log_config_enable ? [1] : []
    content {
      enable = var.log_config_enable
      filter = var.log_config_filter
    }
  }
}
