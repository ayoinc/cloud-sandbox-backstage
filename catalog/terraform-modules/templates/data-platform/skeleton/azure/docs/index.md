# ${{ values.projectName }} data platform

Azure data platform for **${{ values.projectName }}** in the **${{ values.environment }}** environment, region `${{ values.azureRegion }}`{% if values.azureSubscriptionId %}, subscription `${{ values.azureSubscriptionId }}`{% endif %}.

## Architecture

```text
{%- if values.enableStreaming %}
     event producers
            |
   Event Hubs "events"              ${{ values.streamingRetention }} h retention, in whole days
            |
{%- endif %}
{%- if values.enableEtlPipelines and values.etlEngine == 'spark' %}
     Azure Databricks               spark ETL
            |
{%- elif values.enableEtlPipelines %}
    Azure Data Factory              native ETL{% if values.enableOrchestration %}, daily schedule{% endif %}
            |
{%- endif %}
{%- if values.enableOrchestration and not (values.enableEtlPipelines and values.etlEngine == 'native') %}
    Azure Data Factory              orchestration
            |
{%- endif %}
{%- if values.enableDataLake %}
 Data Lake Storage Gen2             raw -> processed -> curated (${{ values.dataLakeStorageClass }})
            |
{%- endif %}
{%- if values.enableDataWarehouse %}
 Synapse dedicated SQL pool         ${{ values.warehouseSize }} warehouse
            |
{%- endif %}
{%- if values.enableBiTools %}
        Power BI
{%- endif %}
{%- if values.enableMlPlatform %}
 Azure Machine Learning             reads the curated zone
{%- endif %}
{%- if values.enableDataCatalog %}
   Microsoft Purview                catalog{% if values.enableDataLineage %} and lineage{% endif %}
{%- endif %}
       Key Vault                    {% if values.enableEncryption %}customer-managed key, {% endif %}secrets
```

## What was chosen

| Setting                 | Value                                                  |
| ----------------------- | ------------------------------------------------------ |
| Region                  | `${{ values.azureRegion }}`                            |
| Subscription            | {% if values.azureSubscriptionId %}`${{ values.azureSubscriptionId }}`{% else %}the subscription of the pipeline's credentials{% endif %} |
| Data lake               | ${{ 'yes' if values.enableDataLake else 'no' }}        |
| Storage class           | `${{ values.dataLakeStorageClass }}`                   |
| Data catalog            | ${{ 'yes' if values.enableDataCatalog else 'no' }}     |
| Data warehouse          | ${{ 'yes' if values.enableDataWarehouse else 'no' }}   |
| Warehouse size          | `${{ values.warehouseSize }}`                          |
| ETL pipelines           | ${{ 'yes' if values.enableEtlPipelines else 'no' }}    |
| ETL engine              | `${{ values.etlEngine }}`                              |
| Orchestration           | ${{ 'yes' if values.enableOrchestration else 'no' }}   |
| Streaming               | ${{ 'yes' if values.enableStreaming else 'no' }}       |
| Streaming retention     | ${{ values.streamingRetention }} hours                 |
| BI integration          | ${{ 'yes' if values.enableBiTools else 'no' }}         |
| ML platform             | ${{ 'yes' if values.enableMlPlatform else 'no' }}      |
| Encryption at rest      | ${{ 'customer-managed key' if values.enableEncryption else 'Microsoft-managed keys' }} |
| Data lineage            | ${{ 'yes' if values.enableDataLineage else 'no' }}     |
| Fine-grained access     | ${{ 'yes' if values.enableAccessControl else 'no' }}   |

These are the contents of `terraform.tfvars`. Change a value there and open a pull request to change the platform. Every value is a Terraform variable, so the same code serves every choice and `terraform test` plans each of them.

## Components

- **Data lake** (`enable_data_lake`): a Data Lake Storage Gen2 account (hierarchical namespace) with the filesystems `raw`, `processed` and `curated`. `data_lake_storage_class` sets the tiering: `standard` keeps the account hot and moves raw and processed data to the cool tier after 90 days; `infrequent` stores the account cool and archives raw and processed data after 180 days; `archive` stores the account cool and archives them after 30 days. The curated zone stays in the account's tier because it is the one that is queried. Production replicates the account to a second region.
- **Data catalog** (`enable_data_catalog`): a Microsoft Purview account. Its managed identity can read the data lake; register the lake as a source in the Purview portal to scan it.
- **Data warehouse** (`enable_data_warehouse`): an Azure Synapse workspace with the dedicated SQL pool `warehouse`. `warehouse_size` selects DW100c (`small`), DW500c (`medium`) or DW1000c (`large`). The SQL administrator password is generated and stored in the Key Vault secret `synapse-sql-admin-password`. The pool is billed while it runs; pause it when it is not needed.
- **ETL** (`enable_etl_pipelines`, `etl_engine`): `native` creates an Azure Data Factory with the pipeline `ingest_raw_to_processed`, which copies the CSV files of the raw zone to Parquet in the processed zone. `spark` creates a premium Azure Databricks workspace and an access connector whose managed identity can use the data lake; register the connector as a storage credential in Unity Catalog.
- **Orchestration** (`enable_orchestration`): a Data Factory schedule trigger runs the ETL every day at `orchestration_hour_utc` (02:00 UTC). For the native engine it runs `ingest_raw_to_processed`; for spark the data factory starts a job cluster in Databricks and runs the notebook `databricks_notebook_path` (`/Shared/etl/main`). The trigger is created stopped, like one made in Data Factory Studio, because a run fails until there is data or a notebook: set `orchestration_trigger_activated = true` to start it.
- **Streaming** (`enable_streaming`): an Event Hubs Standard namespace with the event hub `events` and the consumer group `etl`. Event Hubs Standard keeps events for 1 to 7 whole days, so `streaming_retention_hours` is rounded up to days: ${{ values.streamingRetention }} hours become ${{ (values.streamingRetention / 24) | round(0, 'ceil') }} day(s). The output `streaming_retention_days` shows the result.
- **BI** (`enable_bi_tools`): Power BI workspaces are not Azure resources, so the stack prepares what a workspace needs to connect: the Synapse firewall rule that lets Azure services, including the Power BI service, reach the dedicated SQL endpoint (output `warehouse_sql_endpoint`, database `warehouse`). A Power BI Embedded capacity is created as well once `power_bi_capacity_administrators` names its administrators; it is not created by default because a capacity needs named administrators and is billed by the hour.
- **ML platform** (`enable_ml_platform`): an Azure Machine Learning workspace with its own storage account, Application Insights on a Log Analytics workspace, and the Key Vault. Its managed identity can read the curated zone.
- **Encryption** (`enable_encryption`): one RSA key in the Key Vault encrypts the data lake, the Machine Learning storage account, the Synapse workspace (and with it the SQL pool) and the root storage of Databricks. Each service reads the key with its own managed identity. Without it the same stores use Microsoft-managed keys. Event Hubs Standard and Purview only support Microsoft-managed keys.
- **Data lineage** (`enable_data_lineage`): Data Factory and the Synapse workspace are connected to the Purview account, so their copy and data flow runs report lineage. One step is left for the Purview portal: give the managed identities of the data factory and the Synapse workspace the Data Curator role on the root collection.
- **Access control** (`enable_access_control`): the data lake refuses account keys and SAS tokens, Synapse refuses SQL logins and the Event Hubs namespace refuses shared access keys, so every request is authorised with Microsoft Entra ID. Each managed identity gets a role on the zones it works in only (Synapse: its own filesystem and `curated`; Data Factory and Databricks: all three zones; Machine Learning: `curated`, read only). The groups in `data_engineer_group_object_id` and `data_analyst_group_object_id` get ACL entries: engineers read and write every zone, analysts read `curated`. Without access control the same identities and groups get roles on the whole storage account, and keys and SQL logins stay available.

The resource group, the Log Analytics workspace and Application Insights come from the Terraform modules of [cloud-sandbox-backstage](https://github.com/ayoinc/cloud-sandbox-backstage/tree/main/catalog/terraform-modules/azure/resources).

## How the choices depend on each other

- A Synapse workspace needs a Data Lake Storage Gen2 filesystem. With the warehouse enabled and the data lake disabled, the storage account is still created, with the workspace's filesystem only.
- The native ETL pipeline copies between zones, so it is created only with the data lake. Without it the data factory is created empty.
- Orchestration schedules the ETL. Without an ETL engine the data factory is created with nothing scheduled.
- Lineage is reported to the catalog. Without the data catalog nothing is connected, and the output `data_lineage_enabled` is `false`.
- BI connects to the warehouse. Without the warehouse only the optional capacity is created.
- Encryption creates the key only when there is a store to encrypt.

## Before the first apply

- The pipeline's identity needs the **Owner** role on the subscription (or Contributor together with Role Based Access Control Administrator), because the stack assigns roles.
- Register the resource providers that Terraform does not register itself: `az provider register --namespace Microsoft.Synapse` and `az provider register --namespace Microsoft.Purview`.
- A tenant can hold a limited number of Purview accounts. If the tenant already has one, set `enable_data_catalog = false` or ask Microsoft for a higher quota.
- The storage accounts and the Key Vault accept authenticated requests from any network, because the pipeline runs on GitHub-hosted runners without a fixed address. Set `allowed_ip_ranges` to deny all other networks once Terraform runs from known addresses; the same ranges are then allowed through the Synapse firewall.
- The Synapse administrator is the identity Terraform runs with. Set `warehouse_entra_admin` to a group of people who administer the warehouse.
- Resources that hold data (storage accounts, Key Vault and key, SQL pool, Databricks workspace, Event Hubs) have `prevent_destroy = true`. Disabling such a feature later, or destroying the stack, requires removing that line first.

## Pipeline

The **Terraform** workflow checks every push and pull request without needing an Azure subscription: formatting, `terraform validate`, `terraform test` against mocked providers (`tests/stack.tftest.hcl`), TFLint and a Trivy scan for high and critical findings.

Plan and apply are skipped until these are set in the repository settings:

| Setting                    | Kind     | Purpose                                                                         |
| -------------------------- | -------- | ------------------------------------------------------------------------------- |
| `AZURE_CLIENT_ID`          | secret   | Application or managed identity with a federated credential for this repository |
| `AZURE_TENANT_ID`          | secret   | Microsoft Entra tenant of that identity                                         |
| `AZURE_SUBSCRIPTION_ID`    | secret   | Subscription of the Terraform state{% if not values.azureSubscriptionId %} and of the resources{% endif %} |
| `TF_STATE_RESOURCE_GROUP`  | variable | Resource group of the storage account that holds the Terraform state            |
| `TF_STATE_STORAGE_ACCOUNT` | variable | Storage account that holds the state in its container `tfstate`                 |
| `INFRACOST_API_KEY`        | secret   | Optional. Enables the cost estimate on pushes to `main`                         |

The workflow signs in with GitHub OIDC, so no client secret is stored. The identity needs the Storage Blob Data Contributor role on the state storage account. Every push to `main` then produces a plan. To apply, run the workflow from the Actions tab with **Apply** ticked.

## Outputs

| Output                                | Description                                                        |
| ------------------------------------- | ------------------------------------------------------------------ |
| `resource_group_name`                 | Resource group that holds the platform                             |
| `data_lake_storage_account_name`      | Data Lake Storage Gen2 account                                     |
| `data_lake_dfs_endpoint`              | Endpoint for `abfss://` and Power BI connections to the lake       |
| `data_lake_filesystems`               | Filesystems of the lake                                            |
| `key_vault_name`                      | Key Vault with the encryption key and the SQL administrator password |
| `encryption_key_id`                   | Customer-managed key, when encryption is enabled                   |
| `data_catalog_account_name`           | Purview account                                                    |
| `data_catalog_endpoint`               | Catalog endpoint of the Purview account                            |
| `data_lineage_enabled`                | Whether Data Factory and Synapse report lineage                    |
| `synapse_workspace_name`              | Synapse workspace                                                  |
| `warehouse_sql_endpoint`              | Dedicated SQL endpoint for Power BI and SQL clients                |
| `warehouse_sql_pool_name`             | Dedicated SQL pool and database name                               |
| `warehouse_sql_admin_password_secret` | Key Vault secret with the SQL administrator password               |
| `data_factory_name`                   | Data factory                                                       |
| `etl_pipeline_name`                   | Data Factory pipeline that runs the ETL                            |
| `databricks_workspace_url`            | URL of the Databricks workspace                                    |
| `databricks_access_connector_id`      | Access connector for a Unity Catalog storage credential            |
| `eventhub_namespace_name`             | Event Hubs namespace                                               |
| `eventhub_name`                       | Event hub that receives the stream                                 |
| `streaming_retention_days`            | Days the event hub keeps events                                    |
| `power_bi_capacity_name`              | Power BI Embedded capacity                                         |
| `machine_learning_workspace_name`     | Machine Learning workspace                                         |
