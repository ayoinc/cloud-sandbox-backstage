locals {
  # Keyed by the API identifier: the name in lower case with every run of
  # other characters replaced by a hyphen. The identifier is also the URL path.
  apis = {
    for api in var.apis : trim(replace(lower(api.name), "/[^a-z0-9]+/", "-"), "-") => {
      display_name  = api.name
      description   = api.description != "" ? api.description : null
      backend_url   = api.backend_url != "" ? api.backend_url : null
      open_api_spec = api.open_api_spec != "" ? api.open_api_spec : null
      open_api_format = (
        api.open_api_format != "" ? api.open_api_format :
        endswith(lower(split("?", api.open_api_spec)[0]), ".json") ? "openapi+json-link" : "openapi-link"
      )
    }
  }

  # Portal groups that can see the product: signed-in developers, and
  # anonymous visitors when the portal does not require authentication.
  product_groups = toset(
    !var.enable_portal ? [] :
    var.enable_portal_auth ? ["developers"] : ["developers", "guests"]
  )
}

# Every API of this repository belongs to this product. Callers need a
# subscription key of the product, which is what the rate limit counts against.
resource "azurerm_api_management_product" "this" {
  product_id            = var.service_name
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = module.resource_group.name
  display_name          = var.service_name
  description           = var.description
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_group" "this" {
  for_each = local.product_groups

  product_id          = azurerm_api_management_product.this.product_id
  group_name          = each.value
  api_management_name = azurerm_api_management.this.name
  resource_group_name = module.resource_group.name
}

resource "azurerm_api_management_api" "this" {
  for_each = local.apis

  name                  = each.key
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = module.resource_group.name
  revision              = "1"
  display_name          = each.value.display_name
  description           = each.value.description
  path                  = each.key
  protocols             = ["https"]
  service_url           = each.value.backend_url
  subscription_required = true

  dynamic "import" {
    for_each = each.value.open_api_spec != null ? [each.value.open_api_spec] : []

    content {
      content_format = each.value.open_api_format
      content_value  = import.value
    }
  }
}

resource "azurerm_api_management_product_api" "this" {
  for_each = azurerm_api_management_api.this

  api_name            = each.value.name
  product_id          = azurerm_api_management_product.this.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = module.resource_group.name
}

# rate-limit is not allowed at global scope, so it lives in the product policy.
# It runs before the global policy and therefore counts cached and rejected
# calls as well.
resource "azurerm_api_management_product_policy" "rate_limit" {
  count = var.enable_rate_limiting ? 1 : 0

  product_id          = azurerm_api_management_product.this.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = module.resource_group.name

  xml_content = <<-XML
    <policies>
      <inbound>
        <rate-limit calls="${var.calls_per_minute}" renewal-period="60" />
        <base />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}
