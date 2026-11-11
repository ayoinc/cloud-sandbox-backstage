# Plans the configuration with the committed variable values against mocked
# providers. No AWS credentials are used and nothing is created.

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

mock_provider "archive" {}

variables {
  lambda_package = "tests/fixtures/lambda-package.txt"
}

run "committed_values" {
  command = plan

  assert {
    condition     = aws_api_gateway_stage.this.stage_name == "v${split(".", var.api_version)[0]}"
    error_message = "The stage is not named after the major API version."
  }

  assert {
    condition = alltrue([
      for route in concat(
        [{ method = "GET", path = "/health" }],
        [for e in var.endpoints : { method = upper(e.method), path = e.path }],
        var.enable_crud ? [{ method = "GET", path = "/items" }, { method = "DELETE", path = "/items/{id}" }] : [],
      ) : contains(keys(local.openapi.paths[route.path]), lower(route.method))
    ])
    error_message = "The API definition misses the health check, a configured endpoint or an /items route."
  }

  assert {
    condition     = length(local.openapi.paths["/health"].get.security) == 0
    error_message = "The health check must stay public."
  }

  assert {
    condition = alltrue([
      for e in var.endpoints :
      join(",", flatten([for requirement in local.openapi.paths[e.path][lower(e.method)].security : keys(requirement)])) == (local.auth_type == "none" ? "" : local.auth_type)
    ])
    error_message = "A configured endpoint does not require the configured authentication."
  }

  assert {
    condition     = join(",", keys(local.openapi.components.securitySchemes)) == (local.auth_type == "none" ? "" : local.auth_type)
    error_message = "The API definition must declare exactly the configured security scheme."
  }

  assert {
    condition = (
      length(module.authorizer) == (local.auth_type == "jwt" ? 1 : 0) &&
      length(aws_cognito_user_pool.this) == (local.auth_type == "cognito" ? 1 : 0) &&
      length(aws_api_gateway_usage_plan.default) == (local.auth_type == "apikey" ? 1 : 0)
    )
    error_message = "The authentication resources do not follow enable_auth and auth_type."
  }

  assert {
    condition     = length(aws_dynamodb_table.items) == (var.enable_crud ? 1 : 0)
    error_message = "The items table does not follow enable_crud."
  }

  assert {
    condition = (
      length(module.waf) == (var.enable_waf ? 1 : 0) &&
      length(aws_wafv2_web_acl_association.api) == (var.enable_waf ? 1 : 0)
    )
    error_message = "The web ACL does not follow enable_waf."
  }

  assert {
    condition = (
      length(module.monitoring) == (var.enable_monitoring ? 1 : 0) &&
      length(aws_api_gateway_stage.this.access_log_settings) == (var.enable_monitoring ? 1 : 0) &&
      aws_api_gateway_stage.this.xray_tracing_enabled == var.enable_xray
    )
    error_message = "Monitoring and tracing do not follow enable_monitoring and enable_xray."
  }

  assert {
    condition = one(aws_api_gateway_method_settings.all.settings).throttling_rate_limit == (
      var.enable_rate_limiting ? var.requests_per_second : -1
    )
    error_message = "The stage throttling does not follow enable_rate_limiting and requests_per_second."
  }
}
