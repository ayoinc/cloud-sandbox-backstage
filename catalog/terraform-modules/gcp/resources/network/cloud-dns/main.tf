terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  labels = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.labels
  )

  is_public     = var.visibility == "public"
  is_private    = var.visibility == "private"
  is_forwarding = length(var.forwarding_config_target_name_servers) > 0
  is_peering    = var.peering_config_target_network != null && var.peering_config_target_network != ""
}

resource "google_dns_managed_zone" "this" {
  project     = var.project_id
  name        = var.zone_name
  dns_name    = var.dns_name
  description = var.description
  visibility  = var.visibility
  labels      = local.labels

  dynamic "dnssec_config" {
    for_each = local.is_public ? [1] : []
    content {
      state = var.dnssec_state

      default_key_specs {
        algorithm  = "rsasha256"
        key_length = 2048
        key_type   = "keySigning"
      }

      default_key_specs {
        algorithm  = "rsasha256"
        key_length = 1024
        key_type   = "zoneSigning"
      }
    }
  }

  dynamic "private_visibility_config" {
    for_each = local.is_private ? [1] : []
    content {
      dynamic "networks" {
        for_each = var.private_visibility_config_networks
        content {
          network_url = networks.value
        }
      }
    }
  }

  dynamic "forwarding_config" {
    for_each = local.is_forwarding ? [1] : []
    content {
      dynamic "target_name_servers" {
        for_each = var.forwarding_config_target_name_servers
        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          forwarding_path = target_name_servers.value.forwarding_path
        }
      }
    }
  }

  dynamic "peering_config" {
    for_each = local.is_peering ? [1] : []
    content {
      target_network {
        network_url = var.peering_config_target_network
      }
    }
  }
}

resource "google_dns_record_set" "this" {
  for_each = { for idx, record in var.records : "${record.name}-${record.type}" => record }

  project      = var.project_id
  managed_zone = google_dns_managed_zone.this.name
  name         = each.value.name
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.rrdatas
}

resource "google_dns_policy" "this" {
  for_each = { for idx, policy in var.dns_policies : policy.name => policy }

  project                   = var.project_id
  name                      = each.value.name
  enable_inbound_forwarding = each.value.enable_inbound_forwarding
  enable_logging            = each.value.enable_logging

  dynamic "networks" {
    for_each = each.value.networks != null ? each.value.networks : []
    content {
      network_url = networks.value
    }
  }

  dynamic "alternative_name_server_config" {
    for_each = each.value.alternative_name_server_config != null ? [each.value.alternative_name_server_config] : []
    content {
      dynamic "target_name_servers" {
        for_each = alternative_name_server_config.value.target_name_servers != null ? alternative_name_server_config.value.target_name_servers : []
        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          forwarding_path = lookup(target_name_servers.value, "forwarding_path", null)
        }
      }
    }
  }
}
