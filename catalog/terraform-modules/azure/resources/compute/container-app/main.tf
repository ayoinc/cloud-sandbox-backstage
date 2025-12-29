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
  default_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_container_app_environment" "this" {
  name                       = var.container_app_environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = local.tags
}

resource "azurerm_container_app" "this" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.container_name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name        = env.value.name
          value       = env.value.secret_name == null ? env.value.value : null
          secret_name = env.value.secret_name
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = var.custom_scale_rules
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata
      }
    }

    dynamic "http_scale_rule" {
      for_each = var.http_scale_rules
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests
      }
    }
  }

  ingress {
    external_enabled = var.external_enabled
    target_port      = var.target_port
    transport        = var.ingress_transport

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }

    dynamic "custom_domain" {
      for_each = var.custom_domains
      content {
        name           = custom_domain.value.name
        certificate_id = custom_domain.value.certificate_id
      }
    }
  }

  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  dynamic "dapr" {
    for_each = var.enable_dapr ? [1] : []
    content {
      app_id   = var.dapr_app_id
      app_port = var.dapr_app_port
    }
  }

  tags = local.tags
}
