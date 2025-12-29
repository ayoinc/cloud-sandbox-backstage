terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_compute_router" "router" {
  project     = var.project_id
  name        = var.name
  network     = var.network
  region      = var.region
  description = var.description

  bgp {
    asn                = var.bgp_asn
    advertise_mode     = var.bgp_advertise_mode
    advertised_groups  = var.bgp_advertise_mode == "CUSTOM" ? var.bgp_advertised_groups : null
    keepalive_interval = var.bgp_keepalive_interval

    dynamic "advertised_ip_ranges" {
      for_each = var.bgp_advertise_mode == "CUSTOM" ? var.bgp_advertised_ip_ranges : []
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

resource "google_compute_router_interface" "interface" {
  for_each = { for iface in var.router_interfaces : iface.name => iface }

  project                 = var.project_id
  name                    = each.value.name
  router                  = google_compute_router.router.name
  region                  = var.region
  ip_range                = each.value.ip_range
  vpn_tunnel              = each.value.vpn_tunnel
  interconnect_attachment = each.value.interconnect_attachment
  subnetwork              = each.value.subnetwork
}

resource "google_compute_router_peer" "peer" {
  for_each = { for peer in var.router_peers : peer.name => peer }

  project                   = var.project_id
  name                      = each.value.name
  router                    = google_compute_router.router.name
  region                    = var.region
  interface                 = each.value.interface
  peer_ip_address           = each.value.peer_ip_address
  peer_asn                  = each.value.peer_asn
  advertised_route_priority = each.value.advertised_route_priority

  depends_on = [google_compute_router_interface.interface]
}
