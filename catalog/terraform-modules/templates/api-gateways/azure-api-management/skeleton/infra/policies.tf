locals {
  # Without an explicit list any origin may call the APIs. With a list, the
  # developer portal is added so that its test console keeps working.
  # Browsers reject credentials together with the wildcard origin.
  cors_origins = (
    length(var.cors_allowed_origins) == 0 ? ["*"] :
    distinct(concat(
      var.cors_allowed_origins,
      var.enable_portal ? [azurerm_api_management.this.developer_portal_url] : [],
    ))
  )

  jwt_openid_config_url = coalesce(
    var.jwt_openid_config_url,
    "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0/.well-known/openid-configuration",
  )
  jwt_audiences = coalescelist(var.jwt_audiences, ["api://${var.service_name}"])

  cors_policy = join("\n", concat(
    [
      "<cors allow-credentials=\"${!contains(local.cors_origins, "*")}\">",
      "  <allowed-origins>",
    ],
    [for origin in local.cors_origins : "    <origin>${origin}</origin>"],
    [
      "  </allowed-origins>",
      "  <allowed-methods preflight-result-max-age=\"300\">",
      "    <method>*</method>",
      "  </allowed-methods>",
      "  <allowed-headers>",
      "    <header>*</header>",
      "  </allowed-headers>",
      "  <expose-headers>",
      "    <header>*</header>",
      "  </expose-headers>",
      "</cors>",
    ],
  ))

  jwt_policy = join("\n", concat(
    [
      "<validate-jwt header-name=\"Authorization\" require-scheme=\"Bearer\" failed-validation-httpcode=\"401\" failed-validation-error-message=\"Access token is missing or invalid.\">",
      "  <openid-config url=\"${replace(local.jwt_openid_config_url, "&", "&amp;")}\" />",
      "  <audiences>",
    ],
    [for audience in local.jwt_audiences : "    <audience>${audience}</audience>"],
    [
      "  </audiences>",
      "</validate-jwt>",
    ],
  ))

  # Requests that carry an Authorization header are only cached when tokens
  # are validated, and then each token gets its own cache entry.
  cache_lookup_policy = join("\n", concat(
    [
      "<cache-lookup vary-by-developer=\"false\" vary-by-developer-groups=\"false\" downstream-caching-type=\"none\" allow-private-response-caching=\"${var.enable_jwt}\">",
      "  <vary-by-header>Accept</vary-by-header>",
      "  <vary-by-header>Accept-Charset</vary-by-header>",
    ],
    var.enable_jwt ? ["  <vary-by-header>Authorization</vary-by-header>"] : [],
    ["</cache-lookup>"],
  ))

  cache_store_policy = "<cache-store duration=\"${var.cache_duration_seconds}\" />"

  # CORS comes first so that preflight requests, which carry no token, are
  # answered before the token check.
  global_inbound = concat(
    var.enable_cors ? [local.cors_policy] : [],
    var.enable_jwt ? [local.jwt_policy] : [],
    var.enable_caching ? [local.cache_lookup_policy] : [],
  )
  global_outbound = var.enable_caching ? [local.cache_store_policy] : []

  # Each fragment is indented to its place below <inbound> or <outbound>.
  global_policy = join("\n", concat(
    [
      "<policies>",
      "  <inbound>",
    ],
    [for fragment in local.global_inbound : "    ${indent(4, fragment)}"],
    [
      "  </inbound>",
      "  <backend>",
      "    <forward-request />",
      "  </backend>",
      "  <outbound>",
    ],
    [for fragment in local.global_outbound : "    ${indent(4, fragment)}"],
    [
      "  </outbound>",
      "  <on-error />",
      "</policies>",
    ],
  ))
}

resource "azurerm_api_management_policy" "global" {
  api_management_id = azurerm_api_management.this.id
  xml_content       = local.global_policy
}
