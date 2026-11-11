# ${{ values.projectName }} data platform

Azure data platform for **${{ values.projectName }}** (${{ values.environment }}) in `${{ values.azureRegion }}`, managed with Terraform.

| Part           | What is created                                                                 |
| -------------- | ------------------------------------------------------------------------------- |
| Data lake      | {% if values.enableDataLake %}Data Lake Storage Gen2 account with a raw, a processed and a curated zone, storage class `${{ values.dataLakeStorageClass }}`{% elif values.enableDataWarehouse %}Only the storage account the Synapse workspace requires{% else %}Not enabled{% endif %} |
| Data catalog   | {% if values.enableDataCatalog %}Microsoft Purview account{% else %}Not enabled{% endif %} |
| Data warehouse | {% if values.enableDataWarehouse %}Azure Synapse workspace with a `${{ values.warehouseSize }}` dedicated SQL pool{% else %}Not enabled{% endif %} |
| ETL            | {% if values.enableEtlPipelines and values.etlEngine == 'spark' %}Azure Databricks workspace{% elif values.enableEtlPipelines %}Azure Data Factory{% if values.enableDataLake %} with a pipeline from the raw to the processed zone{% endif %}{% else %}Not enabled{% endif %} |
| Orchestration  | {% if values.enableOrchestration %}Azure Data Factory{% if values.enableEtlPipelines and (values.etlEngine == 'spark' or values.enableDataLake) %} with a daily schedule for the ETL{% endif %}{% else %}Not enabled{% endif %} |
| Streaming      | {% if values.enableStreaming %}Event Hubs namespace with an event hub, ${{ values.streamingRetention }} hours of retention rounded up to whole days{% else %}Not enabled{% endif %} |
| BI             | {% if values.enableBiTools and values.enableDataWarehouse %}The dedicated SQL endpoint is open to the Power BI service{% elif values.enableBiTools %}Enabled, but there is no warehouse for Power BI to connect to{% else %}Not enabled{% endif %} |
| ML platform    | {% if values.enableMlPlatform %}Azure Machine Learning workspace with storage, Key Vault and Application Insights{% else %}Not enabled{% endif %} |
| Encryption     | {% if values.enableEncryption %}Customer-managed key from Key Vault{% else %}Microsoft-managed keys{% endif %} |
| Data lineage   | {% if values.enableDataLineage and values.enableDataCatalog %}Data Factory and Synapse report lineage to Purview{% elif values.enableDataLineage %}Enabled, but there is no data catalog to report to{% else %}Not enabled{% endif %} |
| Access control | {% if values.enableAccessControl %}Microsoft Entra ID only, with roles per data lake zone{% else %}Account-wide roles; keys and SQL logins stay available{% endif %} |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description is in [`docs/index.md`](docs/index.md).

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans every feature combination against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to an Azure subscription and stay skipped until it is configured:

| Setting                    | Kind     | Purpose                                                                   |
| -------------------------- | -------- | ------------------------------------------------------------------------- |
| `AZURE_CLIENT_ID`          | secret   | Application or managed identity with a federated credential for this repository |
| `AZURE_TENANT_ID`          | secret   | Microsoft Entra tenant of that identity                                   |
| `AZURE_SUBSCRIPTION_ID`    | secret   | Subscription of the Terraform state{% if not values.azureSubscriptionId %} and of the resources{% endif %} |
| `TF_STATE_RESOURCE_GROUP`  | variable | Resource group of the storage account that holds the Terraform state      |
| `TF_STATE_STORAGE_ACCOUNT` | variable | Storage account that holds the state in its container `tfstate`           |
| `INFRACOST_API_KEY`        | secret   | Optional. Enables the cost estimate on pushes to `main`                   |

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked. [`docs/index.md`](docs/index.md) lists what the identity needs before the first apply.

## Working locally

```bash
az login
terraform init -backend-config="use_oidc=false" \
  -backend-config="resource_group_name=<state resource group>" \
  -backend-config="storage_account_name=<state storage account>"
terraform plan
```

Use `terraform init -backend=false` to validate and run `terraform test` without access to the state.
