# -----------------------------------------------------------------------------
# Edge: an optional Front Door profile in front of the Application Gateway.
# -----------------------------------------------------------------------------

module "front_door" {
  count  = var.enable_front_door ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/network/front-door?ref=${{ values.moduleRef }}"

  project_name        = var.project_name
  environment         = local.environment_short
  resource_group_name = module.resource_group.name
  profile_name        = "afd-${local.name_prefix}"
  sku_name            = "Standard_AzureFrontDoor"

  endpoints = [
    {
      name    = local.name_prefix
      enabled = true
    }
  ]

  origin_groups = [
    {
      name                     = "gateway"
      session_affinity_enabled = false

      health_probe = {
        interval_in_seconds = 100
        path                = var.health_check_path
        protocol            = local.serves_https ? "Https" : "Http"
        request_type        = "HEAD"
      }

      load_balancing = {
        additional_latency_in_milliseconds = 50
        sample_size                        = 4
        successful_samples_required        = 3
      }
    }
  ]

  # The origin is the public address of the gateway. An address has no name a
  # certificate could be checked against.
  origins = [
    {
      name                           = "gateway"
      origin_group_name              = "gateway"
      host_name                      = azurerm_public_ip.gateway.ip_address
      http_port                      = 80
      https_port                     = 443
      certificate_name_check_enabled = false
      enabled                        = true
      priority                       = 1
      weight                         = 1000
    }
  ]

  # Front Door serves HTTPS on its own domain. It reaches the gateway over
  # HTTPS once the gateway has a certificate.
  routes = [
    {
      name                   = "default"
      endpoint_name          = local.name_prefix
      origin_group_name      = "gateway"
      origin_names           = ["gateway"]
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      forwarding_protocol    = local.serves_https ? "HttpsOnly" : "HttpOnly"
      https_redirect_enabled = true
      cache_enabled          = false
    }
  ]

  tags = local.common_tags
}
