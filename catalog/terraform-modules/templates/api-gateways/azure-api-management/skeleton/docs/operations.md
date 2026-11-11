# Operations

## Publish the developer portal

The developer portal is not visible to visitors until it has been published.

1. Open the instance in the Azure portal.
2. Go to **Developer portal** > **Portal overview**.
3. Select **Publish**.

Publish again after changing the identity providers, for example after
switching `enable_azure_ad`.

## Give a caller access

Every API requires a subscription key of the product named after the service.

- With the portal open, developers sign in, open **Products** and subscribe.
- Otherwise create the subscription in the Azure portal under **APIs** >
  **Subscriptions**, scoped to the product.

Callers send the key in the header `Ocp-Apim-Subscription-Key`. With JWT
validation they also send `Authorization: Bearer <token>`.

## Add or change an API

Edit `infra/apis.auto.tfvars.json` and open a pull request. CI checks the file
and Deploy shows the plan. Renaming an API changes its identifier and path, so
Terraform replaces it.

An imported API is read from `open_api_spec` when it is created. To import a
new version of the document, replace the API:

```bash
terraform apply -replace='azurerm_api_management_api.this["orders-api"]'
```

## Rotate the client secret of the portal sign-in

```bash
terraform apply -replace='azuread_application_password.portal[0]'
```

Terraform creates a new secret and updates the identity provider. Publish the
portal afterwards.

## Read the logs

With Log Analytics enabled, gateway requests are in the workspace:

```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| summarize Requests = count() by ApiId, ResponseCode
| order by Requests desc
```

With Application Insights enabled, the same requests appear under
**Transaction search** and **Failures** of the Application Insights resource.

## Change the tier or the number of units

Change `sku` or `sku_capacity` in `infra/terraform.tfvars`. Azure updates the
instance in place; the update takes up to 45 minutes and clears the built-in
cache.

## Delete the instance

`terraform destroy` removes every resource. Azure keeps a deleted instance for
48 hours; the provider purges it on destroy, so the name is free again
afterwards.
