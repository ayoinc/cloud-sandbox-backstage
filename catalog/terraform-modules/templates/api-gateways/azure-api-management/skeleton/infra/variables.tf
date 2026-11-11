variable "service_name" {
  description = "Name of the API Management instance. Globally unique; also used in the names of the other resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,30}[a-z0-9])?$", var.service_name))
    error_message = "service_name must start with a letter, contain only lowercase letters, digits and hyphens, end with a letter or digit and be at most 32 characters long."
  }
}

variable "description" {
  description = "Description of the service. Shown on the product in the developer portal."
  type        = string
}

variable "location" {
  description = "Azure region name, for example eastus."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be a region name such as eastus or westeurope, not a display name."
  }
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod", "test", "sandbox"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, test, sandbox."
  }
}

variable "sku" {
  description = "Pricing tier of the API Management instance."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Developer", "Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be one of: Developer, Basic, Standard, Premium."
  }
}

variable "sku_capacity" {
  description = "Number of scale units. The Developer tier supports exactly 1, Basic at most 2."
  type        = number
  default     = 1

  validation {
    condition     = var.sku_capacity >= 1 && floor(var.sku_capacity) == var.sku_capacity
    error_message = "sku_capacity must be a whole number of at least 1."
  }
}

variable "publisher_name" {
  description = "Organisation name shown in the developer portal and in notification emails."
  type        = string
  default     = "Platform Team"
}

variable "publisher_email" {
  description = "Address that receives the system notifications of the instance."
  type        = string
  default     = "platform-team@example.com"
}

variable "tags" {
  description = "Additional tags for every resource."
  type        = map(string)
  default     = {}
}

variable "enable_portal" {
  description = "Open the developer portal: allow sign-up and show the product to developers."
  type        = bool
  default     = true
}

variable "enable_portal_auth" {
  description = "Send anonymous visitors of the developer portal to the sign-in page. When false, anonymous visitors can browse the APIs."
  type        = bool
  default     = true
}

variable "enable_azure_ad" {
  description = "Let developers sign in to the developer portal with Microsoft Entra ID. Needs enable_portal; has no effect in the Basic tier."
  type        = bool
  default     = true
}

variable "enable_jwt" {
  description = "Require a valid JWT access token on every API call."
  type        = bool
  default     = true
}

variable "jwt_openid_config_url" {
  description = "OpenID Connect metadata URL of the token issuer. Defaults to the v2.0 endpoint of the tenant the instance is deployed to."
  type        = string
  default     = null

  validation {
    condition     = var.jwt_openid_config_url == null || can(regex("^https://[^\\s<>\"']+$", var.jwt_openid_config_url))
    error_message = "jwt_openid_config_url must be an https URL."
  }
}

variable "jwt_audiences" {
  description = "Accepted values of the aud claim. Defaults to api://<service_name>."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for audience in var.jwt_audiences : can(regex("^[^\\s<>&\"']+$", audience))])
    error_message = "jwt_audiences entries must not contain whitespace, quotes, <, > or &."
  }
}

variable "enable_rate_limiting" {
  description = "Limit the number of calls per subscription of the product."
  type        = bool
  default     = true
}

variable "calls_per_minute" {
  description = "Calls allowed per subscription in 60 seconds."
  type        = number
  default     = 1000

  validation {
    condition     = var.calls_per_minute >= 1 && floor(var.calls_per_minute) == var.calls_per_minute
    error_message = "calls_per_minute must be a whole number of at least 1."
  }
}

variable "enable_cors" {
  description = "Answer cross-origin requests on every API."
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "Origins allowed to call the APIs from a browser, for example https://app.example.com. Empty allows any origin."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for origin in var.cors_allowed_origins : can(regex("^https?://[^\\s<>&\"'/*]+$", origin))])
    error_message = "cors_allowed_origins entries must be origins such as https://app.example.com, without a path."
  }
}

variable "enable_caching" {
  description = "Cache GET responses in the built-in cache of the instance."
  type        = bool
  default     = true
}

variable "cache_duration_seconds" {
  description = "Time a cached response is kept."
  type        = number
  default     = 300

  validation {
    condition     = var.cache_duration_seconds >= 1 && floor(var.cache_duration_seconds) == var.cache_duration_seconds
    error_message = "cache_duration_seconds must be a whole number of at least 1."
  }
}

variable "enable_application_insights" {
  description = "Send request telemetry of every API to Application Insights."
  type        = bool
  default     = true
}

variable "application_insights_sampling_percentage" {
  description = "Share of requests sent to Application Insights."
  type        = number
  default     = 100

  validation {
    condition     = var.application_insights_sampling_percentage >= 0 && var.application_insights_sampling_percentage <= 100
    error_message = "application_insights_sampling_percentage must be between 0 and 100."
  }
}

variable "enable_log_analytics" {
  description = "Send gateway logs and metrics to a Log Analytics workspace."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention of the Log Analytics workspace in days."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730 && floor(var.log_retention_days) == var.log_retention_days
    error_message = "log_retention_days must be a whole number between 30 and 730."
  }
}

variable "apis" {
  description = "APIs published through the gateway. An entry with open_api_spec is imported from that URL, any other entry is created without operations. open_api_format overrides the import format derived from the URL."
  type = list(object({
    name            = string
    backend_url     = optional(string, "")
    description     = optional(string, "")
    open_api_spec   = optional(string, "")
    open_api_format = optional(string, "")
  }))
  default = []

  validation {
    condition     = alltrue([for api in var.apis : can(regex("[A-Za-z0-9]", api.name))])
    error_message = "Every API name must contain a letter or a digit."
  }

  validation {
    condition = length(distinct([
      for api in var.apis : trim(replace(lower(api.name), "/[^a-z0-9]+/", "-"), "-")
    ])) == length(var.apis)
    error_message = "API names must stay distinct after lowercasing and replacing other characters with hyphens."
  }

  validation {
    condition = alltrue([
      for api in var.apis : contains(
        ["", "openapi-link", "openapi+json-link", "swagger-link-json", "wadl-link-json", "wsdl-link"],
        api.open_api_format,
      )
    ])
    error_message = "open_api_format must be one of: openapi-link, openapi+json-link, swagger-link-json, wadl-link-json, wsdl-link."
  }
}
