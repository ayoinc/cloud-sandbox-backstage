# Configuration

The settings of the instance are Terraform variables. Their values are in
`infra/terraform.tfvars`, the APIs are in `infra/apis.auto.tfvars.json`, and
`infra/variables.tf` describes every variable with its default. Change a value,
open a pull request, and the Deploy workflow shows the plan.

## Instance

| Variable | Effect |
| --- | --- |
| `service_name` | Name of the instance and part of every other resource name. Changing it replaces the instance. |
| `description` | Description of the product in the developer portal. |
| `location` | Azure region. Changing it replaces every resource. |
| `environment` | Part of the resource names and tags. Default `prod`. |
| `sku`, `sku_capacity` | Pricing tier and number of units, combined into `sku_name` (`Standard_1`). |
| `publisher_name`, `publisher_email` | Shown in the portal and used for system notifications. The values in `terraform.tfvars` are placeholders: set real ones before the first deployment. |
| `tags` | Additional tags. |

The instance has a system-assigned managed identity. Its object ID is the
output `identity_principal_id`; use it to grant the gateway access to backends
or key vaults.

### Pricing tiers

| Tier | Notes |
| --- | --- |
| Developer | No SLA, one unit. For evaluation and test environments. |
| Basic | Up to two units. No Microsoft Entra ID sign-in on the developer portal. |
| Standard | Up to four units. |
| Premium | Multiple regions, availability zones and virtual networks; none of these is configured by this repository. |

Creating an instance in any of these tiers takes 30 to 60 minutes.

## Developer portal

| Variable | Effect |
| --- | --- |
| `enable_portal` | `true`: visitors can sign up, the product is visible to the `developers` group, and the output `developer_portal_url` is set. `false`: sign-up is disabled, visitors are sent to the sign-in page, and the product is visible to administrators only. |
| `enable_portal_auth` | `true`: anonymous visitors are sent to the sign-in page. `false`: anonymous visitors can browse the portal and the product is also visible to the `guests` group. |
| `enable_azure_ad` | Adds Microsoft Entra ID as an identity provider of the portal. Requires `enable_portal`; not created in the Basic tier. |

These tiers always host the developer portal; it cannot be removed. Terraform
cannot publish it either: an administrator publishes the portal once, and again
after a change of the identity providers. See [Operations](operations.md).

### Microsoft Entra ID sign-in

The identity provider needs an app registration with a client secret. Terraform
creates both (`infra/identity.tf`) instead of asking for a client ID and secret,
because:

- the redirect URI of the app registration is derived from the portal URL of
  the instance, so the two cannot drift apart;
- no secret has to be created by hand and stored as a pipeline secret.

Consequences:

- The deployment identity needs the Microsoft Graph application permission
  `Application.ReadWrite.OwnedBy` (or the directory role Application
  Developer). See [Deployment](deployment.md).
- The client secret is stored in the Terraform state. Keep access to the state
  container restricted.
- Microsoft Entra ID decides when the secret expires (two years unless a
  tenant policy sets a shorter period). Rotation is described in
  [Operations](operations.md).
- The app registration is single-tenant and requests the delegated permission
  `User.Read`. Users of the deployment tenant can sign in.

To use an app registration that already exists, delete the three `azuread_*`
resources from `infra/identity.tf` and pass its client ID and secret to
`azurerm_api_management_identity_provider_aad` through sensitive variables.

## JWT validation

With `enable_jwt` the global policy contains `validate-jwt`: every call to
every API must carry `Authorization: Bearer <token>`, otherwise the gateway
answers 401.

| Variable | Default | Effect |
| --- | --- | --- |
| `jwt_openid_config_url` | v2.0 metadata of the deployment tenant: `https://login.microsoftonline.com/<tenant>/v2.0/.well-known/openid-configuration` | Signing keys and issuer the tokens are checked against. |
| `jwt_audiences` | `api://<service_name>` | Accepted values of the `aud` claim. |

The defaults do not match any token until an application exists for the APIs:

1. Register an application for the APIs in Microsoft Entra ID and expose a scope
   or an app role.
2. Set `accessTokenAcceptedVersion` to `2` in its manifest. Version 2 tokens
   are issued by the v2.0 endpoint and carry the client ID of the application
   in `aud`.
3. Set `jwt_audiences` to that client ID.

Applications that receive version 1 tokens carry the application ID URI in
`aud` and are issued by `https://sts.windows.net/<tenant>/`. For those, set
`jwt_openid_config_url` to
`https://login.microsoftonline.com/<tenant>/.well-known/openid-configuration`
and `jwt_audiences` to the application ID URI.

## Rate limiting

`rate-limit` is not allowed in the global policy. The configuration therefore
creates one product, named after the service, attaches every API to it and
puts the limit in the product policy:

```xml
<rate-limit calls="1000" renewal-period="60" />
```

| Variable | Effect |
| --- | --- |
| `enable_rate_limiting` | Creates the product policy. |
| `calls_per_minute` | Calls allowed per subscription in 60 seconds. Further calls get 429. |

Every API requires a subscription key. Callers subscribe to the product in the
developer portal, or an administrator creates the subscription. The limit is
counted per subscription of the product, before the global policy runs, so
cached and rejected calls count as well. The built-in all-access subscription
is not part of the product and is not limited.

## CORS

With `enable_cors` the global policy answers preflight requests and adds the
CORS headers.

| Variable | Effect |
| --- | --- |
| `cors_allowed_origins` | Empty (default): any origin, without credentials. A list of origins: only these, plus the developer portal when it is open, with credentials allowed. |

All methods and headers are allowed. The policy is placed before the token
check because preflight requests carry no token.

## Response caching

With `enable_caching` the global policy looks up GET responses in the built-in
cache of the instance and stores backend responses for
`cache_duration_seconds` (default 300).

- Without JWT validation, requests with an `Authorization` header are not
  cached.
- With JWT validation, responses are cached per value of the `Authorization`
  header, so one caller never receives the cached response of another.

The built-in cache is lost when the instance is updated or scaled.

## APIs

`infra/apis.auto.tfvars.json` holds the list:

```json
{
  "apis": [
    {
      "name": "Orders API",
      "backend_url": "https://orders.example.com",
      "description": "Order placement and tracking",
      "open_api_spec": "https://example.com/orders/openapi.yaml"
    },
    {
      "name": "Inventory API",
      "backend_url": "https://inventory.example.com"
    }
  ]
}
```

| Field | Required | Effect |
| --- | --- | --- |
| `name` | Yes | Display name. Lowercased, with other characters replaced by hyphens, it is the API identifier and the URL path: `Orders API` is served at `https://<service_name>.azure-api.net/orders-api`. |
| `backend_url` | No | Base URL the gateway forwards to. |
| `description` | No | Shown in the developer portal. |
| `open_api_spec` | No | URL of an OpenAPI document. The operations are imported from it when Terraform applies. API Management downloads the document, so the URL must be reachable from the internet without authentication. |
| `open_api_format` | No | Import format. Default: `openapi+json-link` when the URL path ends in `.json`, otherwise `openapi-link` (OpenAPI 3 in YAML). Use `swagger-link-json` for Swagger 2.0. |

An entry without `open_api_spec` becomes an API without operations; add
operations in the Azure portal or with `azurerm_api_management_api_operation`.
Names must stay distinct after the conversion to identifiers. An empty list is
valid: the product then has no APIs.

New instances also contain the sample Echo API and the products Starter and
Unlimited that Azure creates. Terraform does not manage them.

## Monitoring

| Variable | Effect |
| --- | --- |
| `enable_application_insights` | Application Insights resource, a logger on the instance and a diagnostic that records the requests of every API. `application_insights_sampling_percentage` (default 100) sets the share of requests recorded. |
| `enable_log_analytics` | Diagnostic setting that sends `GatewayLogs` and all metrics to the Log Analytics workspace. Logs arrive in the table `ApiManagementGatewayLogs`. |
| `log_retention_days` | Retention of the workspace, 30 to 730 days. |

Application Insights stores its data in a Log Analytics workspace. The
workspace `log-<service_name>-<environment>-<location>` is therefore created
when either switch is on.

## Shared modules

The resource group, the Log Analytics workspace, Application Insights and the
diagnostic setting come from the shared Terraform modules of the platform,
pinned to a commit. The diagnostic setting and Application Insights modules use
arguments that version 5 of the `azurerm` provider removed, so the provider is
pinned to `~> 4.81.0` in `infra/versions.tf`.

## Changing the policies

The global policy is assembled in `infra/policies.tf` from one fragment per
switch. To add a policy to every API, add a fragment to `global_inbound` or
`global_outbound`. Policies for a single API belong in an
`azurerm_api_management_api_policy` resource.
