variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "container_registries" {
  type = map(object({
    sku                           = optional(string, "Premium")
    admin_enabled                 = optional(bool, false)
    public_network_access_enabled = optional(bool, false)
    zone_redundancy_enabled       = optional(bool, true)
    anonymous_pull_enabled        = optional(bool, false)
    data_endpoint_enabled         = optional(bool, true)
    network_rule_bypass_option    = optional(string, "AzureServices")
    georeplications = optional(list(object({
      location                = string
      zone_redundancy_enabled = optional(bool, true)
    })), [])
    retention_policy = optional(object({
      days    = optional(number, 30)
      enabled = optional(bool, true)
    }))
    trust_policy_enabled = optional(bool, true)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    encryption = optional(object({
      key_vault_key_id   = string
      identity_client_id = string
    }))
    network_rule_set = optional(object({
      default_action = optional(string, "Deny")
      ip_rules       = optional(list(string), [])
    }))
  }))
  default = {}
}

variable "acr_scope_maps" {
  type = map(object({
    registry_key = string
    actions      = list(string)
  }))
  default = {}
}

variable "acr_tokens" {
  type = map(object({
    registry_key  = string
    scope_map_key = string
    enabled       = optional(bool, true)
  }))
  default = {}
}

variable "acr_webhooks" {
  type = map(object({
    registry_key   = string
    service_uri    = string
    actions        = list(string)
    status         = optional(string, "enabled")
    scope          = optional(string)
    custom_headers = optional(map(string))
  }))
  default = {}
}

variable "acr_tasks" {
  type = map(object({
    registry_key = string
    enabled      = optional(bool, true)
    platform = optional(object({
      os           = optional(string, "Linux")
      architecture = optional(string, "amd64")
    }))
    docker_step = optional(object({
      dockerfile_path      = string
      context_path         = string
      context_access_token = string
      image_names          = list(string)
      cache_enabled        = optional(bool, true)
      push_enabled         = optional(bool, true)
    }))
    timer_triggers = optional(list(object({
      name     = string
      schedule = string
      enabled  = optional(bool, true)
    })), [])
  }))
  default = {}
}

variable "acr_private_endpoints" {
  type = map(object({
    registry_key        = string
    subnet_id           = string
    private_dns_zone_id = optional(string)
  }))
  default = {}
}

variable "container_groups" {
  type = map(object({
    os_type         = optional(string, "Linux")
    restart_policy  = optional(string, "Always")
    ip_address_type = optional(string, "Private")
    dns_name_label  = optional(string)
    subnet_ids      = optional(list(string))
    containers = list(object({
      name   = string
      image  = string
      cpu    = number
      memory = number
      ports = optional(list(object({
        port     = number
        protocol = optional(string, "TCP")
      })), [])
      environment_variables        = optional(map(string))
      secure_environment_variables = optional(map(string))
      volumes = optional(list(object({
        name                 = string
        mount_path           = string
        read_only            = optional(bool, false)
        empty_dir            = optional(bool, false)
        storage_account_name = optional(string)
        storage_account_key  = optional(string)
        share_name           = optional(string)
      })), [])
      liveness_probe = optional(object({
        exec                  = optional(list(string))
        initial_delay_seconds = optional(number, 0)
        period_seconds        = optional(number, 10)
        failure_threshold     = optional(number, 3)
        success_threshold     = optional(number, 1)
        timeout_seconds       = optional(number, 1)
        http_get = optional(object({
          path   = string
          port   = number
          scheme = optional(string, "Http")
        }))
      }))
    }))
    image_registry_credentials = optional(list(object({
      server                    = string
      username                  = optional(string)
      password                  = optional(string)
      user_assigned_identity_id = optional(string)
    })), [])
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
  }))
  default = {}
}
