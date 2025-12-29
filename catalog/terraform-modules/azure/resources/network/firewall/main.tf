terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

locals {
  firewall_name = "${var.project_name}-${var.environment}-${var.name}-fw"
  policy_name   = "${var.project_name}-${var.environment}-${var.name}-fw-policy"
  pip_name      = "${var.project_name}-${var.environment}-${var.name}-fw-pip"

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_public_ip" "firewall" {
  name                = local.pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones

  tags = local.tags
}

resource "azurerm_firewall_policy" "this" {
  name                = local.policy_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_tier

  threat_intelligence_mode = var.threat_intel_mode

  dynamic "dns" {
    for_each = var.dns_servers != null || var.dns_proxy_enabled ? [1] : []
    content {
      servers       = var.dns_servers
      proxy_enabled = var.dns_proxy_enabled
    }
  }

  tags = local.tags
}

resource "azurerm_firewall" "this" {
  name                = local.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id
  zones               = var.zones

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = local.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  count = length(var.network_rule_collections) > 0 || length(var.application_rule_collections) > 0 || length(var.nat_rule_collections) > 0 ? 1 : 0

  name               = "${local.firewall_name}-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 100

  dynamic "network_rule_collection" {
    for_each = var.network_rule_collections
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          protocols             = rule.value.protocols
          source_addresses      = lookup(rule.value, "source_addresses", null)
          source_ip_groups      = lookup(rule.value, "source_ip_groups", null)
          destination_addresses = lookup(rule.value, "destination_addresses", null)
          destination_ip_groups = lookup(rule.value, "destination_ip_groups", null)
          destination_fqdns     = lookup(rule.value, "destination_fqdns", null)
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }

  dynamic "application_rule_collection" {
    for_each = var.application_rule_collections
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name              = rule.value.name
          source_addresses  = lookup(rule.value, "source_addresses", null)
          source_ip_groups  = lookup(rule.value, "source_ip_groups", null)
          destination_fqdns = lookup(rule.value, "destination_fqdns", null)

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }

  dynamic "nat_rule_collection" {
    for_each = var.nat_rule_collections
    content {
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority
      action   = nat_rule_collection.value.action

      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.value.name
          protocols           = rule.value.protocols
          source_addresses    = lookup(rule.value, "source_addresses", null)
          source_ip_groups    = lookup(rule.value, "source_ip_groups", null)
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}
