# Azure Container Services Module (ACR, ACI)

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

# Azure Container Registry
resource "azurerm_container_registry" "this" {
  for_each                      = var.container_registries
  name                          = each.key
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = each.value.sku
  admin_enabled                 = each.value.admin_enabled
  public_network_access_enabled = each.value.public_network_access_enabled
  zone_redundancy_enabled       = each.value.zone_redundancy_enabled
  anonymous_pull_enabled        = each.value.anonymous_pull_enabled
  data_endpoint_enabled         = each.value.data_endpoint_enabled
  network_rule_bypass_option    = each.value.network_rule_bypass_option

  dynamic "georeplications" {
    for_each = each.value.georeplications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = var.tags
    }
  }

  dynamic "retention_policy" {
    for_each = each.value.retention_policy != null ? [each.value.retention_policy] : []
    content {
      days    = retention_policy.value.days
      enabled = retention_policy.value.enabled
    }
  }

  dynamic "trust_policy" {
    for_each = each.value.trust_policy_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []
    content {
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  dynamic "network_rule_set" {
    for_each = each.value.network_rule_set != null ? [each.value.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }

  tags = var.tags
}

# ACR Scope Maps
resource "azurerm_container_registry_scope_map" "this" {
  for_each                = var.acr_scope_maps
  name                    = each.key
  container_registry_name = azurerm_container_registry.this[each.value.registry_key].name
  resource_group_name     = var.resource_group_name
  actions                 = each.value.actions
}

# ACR Tokens
resource "azurerm_container_registry_token" "this" {
  for_each                = var.acr_tokens
  name                    = each.key
  container_registry_name = azurerm_container_registry.this[each.value.registry_key].name
  resource_group_name     = var.resource_group_name
  scope_map_id            = azurerm_container_registry_scope_map.this[each.value.scope_map_key].id
  enabled                 = each.value.enabled
}

# ACR Webhooks
resource "azurerm_container_registry_webhook" "this" {
  for_each            = var.acr_webhooks
  name                = each.key
  registry_name       = azurerm_container_registry.this[each.value.registry_key].name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_uri         = each.value.service_uri
  actions             = each.value.actions
  status              = each.value.status
  scope               = each.value.scope
  custom_headers      = each.value.custom_headers
  tags                = var.tags
}

# ACR Tasks
resource "azurerm_container_registry_task" "this" {
  for_each              = var.acr_tasks
  name                  = each.key
  container_registry_id = azurerm_container_registry.this[each.value.registry_key].id
  enabled               = each.value.enabled

  dynamic "platform" {
    for_each = each.value.platform != null ? [each.value.platform] : []
    content {
      os           = platform.value.os
      architecture = platform.value.architecture
    }
  }

  dynamic "docker_step" {
    for_each = each.value.docker_step != null ? [each.value.docker_step] : []
    content {
      dockerfile_path      = docker_step.value.dockerfile_path
      context_path         = docker_step.value.context_path
      context_access_token = docker_step.value.context_access_token
      image_names          = docker_step.value.image_names
      cache_enabled        = docker_step.value.cache_enabled
      push_enabled         = docker_step.value.push_enabled
    }
  }

  dynamic "timer_trigger" {
    for_each = each.value.timer_triggers
    content {
      name     = timer_trigger.value.name
      schedule = timer_trigger.value.schedule
      enabled  = timer_trigger.value.enabled
    }
  }

  tags = var.tags
}

# Private Endpoints for ACR
resource "azurerm_private_endpoint" "acr" {
  for_each            = var.acr_private_endpoints
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "${each.key}-connection"
    private_connection_resource_id = azurerm_container_registry.this[each.value.registry_key].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [each.value.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# Azure Container Instances
resource "azurerm_container_group" "this" {
  for_each            = var.container_groups
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = each.value.os_type
  restart_policy      = each.value.restart_policy
  ip_address_type     = each.value.ip_address_type
  dns_name_label      = each.value.dns_name_label
  subnet_ids          = each.value.subnet_ids

  dynamic "container" {
    for_each = each.value.containers
    content {
      name   = container.value.name
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      dynamic "ports" {
        for_each = container.value.ports
        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }

      dynamic "environment_variables" {
        for_each = container.value.environment_variables != null ? [container.value.environment_variables] : []
        content {
        }
      }

      secure_environment_variables = container.value.secure_environment_variables

      dynamic "volume" {
        for_each = container.value.volumes
        content {
          name                 = volume.value.name
          mount_path           = volume.value.mount_path
          read_only            = volume.value.read_only
          empty_dir            = volume.value.empty_dir
          storage_account_name = volume.value.storage_account_name
          storage_account_key  = volume.value.storage_account_key
          share_name           = volume.value.share_name
        }
      }

      dynamic "liveness_probe" {
        for_each = container.value.liveness_probe != null ? [container.value.liveness_probe] : []
        content {
          exec                  = liveness_probe.value.exec
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          period_seconds        = liveness_probe.value.period_seconds
          failure_threshold     = liveness_probe.value.failure_threshold
          success_threshold     = liveness_probe.value.success_threshold
          timeout_seconds       = liveness_probe.value.timeout_seconds

          dynamic "http_get" {
            for_each = liveness_probe.value.http_get != null ? [liveness_probe.value.http_get] : []
            content {
              path   = http_get.value.path
              port   = http_get.value.port
              scheme = http_get.value.scheme
            }
          }
        }
      }
    }
  }

  dynamic "image_registry_credential" {
    for_each = each.value.image_registry_credentials
    content {
      server                    = image_registry_credential.value.server
      username                  = image_registry_credential.value.username
      password                  = image_registry_credential.value.password
      user_assigned_identity_id = image_registry_credential.value.user_assigned_identity_id
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = var.tags
}
