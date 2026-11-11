# -----------------------------------------------------------------------------
# Web tier: Application Gateway, the public entry point of every compute type.
# -----------------------------------------------------------------------------

locals {
  serves_https = var.tls_certificate_secret_id != null

  # Container Apps are addressed by name over HTTPS. The AKS ingress is an
  # internal load balancer with a fixed address in the ingress subnet. Scale set
  # instances register themselves in the backend pool.
  backend_protocol = local.runs_container_apps ? "Https" : "Http"
  backend_port     = local.runs_container_apps ? 443 : var.app_port
  aks_ingress_ip   = cidrhost(local.subnet_prefixes.ingress, 10)

  availability_zones = local.is_production ? ["1", "2", "3"] : null
}

resource "azurerm_public_ip" "gateway" {
  name                = "pip-agw-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = local.availability_zones
  tags                = local.common_tags
}

# The gateway reads its TLS certificate from Key Vault with this identity.
resource "azurerm_user_assigned_identity" "gateway" {
  name                = "id-agw-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = local.common_tags
}

# Front Door sends the ID of its profile with every request. Requests that
# reach the gateway without it did not come through this stack's Front Door.
data "azurerm_cdn_frontdoor_profile" "main" {
  count = var.enable_waf && var.enable_front_door ? 1 : 0

  name                = module.front_door[0].profile_name
  resource_group_name = module.resource_group.name

  depends_on = [module.front_door]
}

resource "azurerm_web_application_firewall_policy" "gateway" {
  count = var.enable_waf ? 1 : 0

  name                = "waf-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  dynamic "custom_rules" {
    for_each = data.azurerm_cdn_frontdoor_profile.main

    content {
      name      = "RequireFrontDoorId"
      priority  = 10
      rule_type = "MatchRule"
      action    = "Block"

      match_conditions {
        match_variables {
          variable_name = "RequestHeaders"
          selector      = "X-Azure-FDID"
        }

        operator           = "Equal"
        negation_condition = true
        match_values       = [custom_rules.value.resource_guid]
      }
    }
  }

  tags = local.common_tags
}

resource "azurerm_application_gateway" "main" {
  name                = "agw-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  zones               = local.availability_zones
  enable_http2        = true
  firewall_policy_id  = one(azurerm_web_application_firewall_policy.gateway[*].id)

  sku {
    name = var.enable_waf ? "WAF_v2" : "Standard_v2"
    tier = var.enable_waf ? "WAF_v2" : "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = local.is_production ? 2 : 1
    max_capacity = 10
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gateway.id]
  }

  gateway_ip_configuration {
    name      = "gateway"
    subnet_id = module.network.subnet_ids["gateway"]
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  dynamic "frontend_port" {
    for_each = local.serves_https ? [443] : []

    content {
      name = "https"
      port = frontend_port.value
    }
  }

  backend_address_pool {
    name         = "app"
    fqdns        = local.runs_container_apps ? [azurerm_container_app.app[0].ingress[0].fqdn] : null
    ip_addresses = local.runs_aks ? [local.aks_ingress_ip] : null
  }

  backend_http_settings {
    name                                = "app"
    protocol                            = local.backend_protocol
    port                                = local.backend_port
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 30
    probe_name                          = "app"
    pick_host_name_from_backend_address = local.runs_container_apps
  }

  probe {
    name                                      = "app"
    protocol                                  = local.backend_protocol
    path                                      = var.health_check_path
    host                                      = local.runs_container_apps ? null : "127.0.0.1"
    pick_host_name_from_backend_http_settings = local.runs_container_apps
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  dynamic "http_listener" {
    for_each = local.serves_https ? ["https"] : []

    content {
      name                           = http_listener.value
      frontend_ip_configuration_name = "public"
      frontend_port_name             = "https"
      protocol                       = "Https"
      ssl_certificate_name           = "app"
    }
  }

  dynamic "ssl_certificate" {
    for_each = local.serves_https ? [var.tls_certificate_secret_id] : []

    content {
      name                = "app"
      key_vault_secret_id = ssl_certificate.value
    }
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  # Without a certificate the HTTP listener serves the application. With one it
  # redirects to the HTTPS listener.
  request_routing_rule {
    name                        = "http"
    rule_type                   = "Basic"
    priority                    = 100
    http_listener_name          = "http"
    backend_address_pool_name   = local.serves_https ? null : "app"
    backend_http_settings_name  = local.serves_https ? null : "app"
    redirect_configuration_name = local.serves_https ? "https" : null
  }

  dynamic "request_routing_rule" {
    for_each = local.serves_https ? ["https"] : []

    content {
      name                       = request_routing_rule.value
      rule_type                  = "Basic"
      priority                   = 110
      http_listener_name         = "https"
      backend_address_pool_name  = "app"
      backend_http_settings_name = "app"
    }
  }

  dynamic "redirect_configuration" {
    for_each = local.serves_https ? ["https"] : []

    content {
      name                 = redirect_configuration.value
      redirect_type        = "Permanent"
      target_listener_name = "https"
      include_path         = true
      include_query_string = true
    }
  }

  tags = local.common_tags

  depends_on = [
    azurerm_network_security_rule.gateway_management,
    azurerm_network_security_rule.gateway_web,
    azurerm_private_dns_a_record.container_apps,
    azurerm_private_dns_zone_virtual_network_link.container_apps,
  ]
}

module "gateway_diagnostics" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/diagnostic-settings?ref=${{ values.moduleRef }}"

  project_name               = var.project_name
  environment                = local.environment_short
  name                       = "to-log-analytics"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = module.log_analytics.workspace_id

  enabled_logs = [
    { category_group = "allLogs" }
  ]

  metrics = [
    { category = "AllMetrics" }
  ]
}
