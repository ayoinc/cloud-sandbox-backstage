# ${{ values.projectName }} data platform

AWS data platform for **${{ values.projectName }}** in the **${{ values.environment }}** environment, region `${{ values.awsRegion }}`.

## Architecture

```text
{%- if values.enableStreaming %}
  producers --> Kinesis data stream{% if values.enableDataLake %} --> Firehose --+{% endif %}
{%- if values.enableDataLake %}
                                                |
{%- endif %}
{%- endif %}
{%- if values.enableDataLake %}
  S3 data lake:   raw zone  -->  processed zone  -->  curated zone
{%- endif %}
{%- if values.enableEtlPipelines %}
  ETL:            {% if values.etlEngine == 'native' %}AWS Glue jobs{% else %}Spark jobs on EMR Serverless{% endif %} (raw to processed, processed to curated)
{%- endif %}
{%- if values.enableDataCatalog %}
  Catalog:        Glue database per zone{% if values.enableDataLake %}, filled by a crawler per zone{% endif %}
{%- endif %}
{%- if values.enableOrchestration %}
  Orchestration:  Step Functions state machine runs the steps in order
{%- endif %}
{%- if values.enableDataWarehouse %}
  Warehouse:      Amazon Redshift (${{ values.warehouseSize }}){% if values.enableDataLake and values.enableDataCatalog %}, reads the curated zone{% endif %}
{%- endif %}
{%- if values.enableBiTools %}
  BI:             Athena workgroup and IAM role for QuickSight and other BI tools
{%- endif %}
{%- if values.enableMlPlatform %}
  ML:             SageMaker domain, reads the processed and curated zones
{%- endif %}
{%- if values.enableDataLineage %}
  Lineage:        Amazon DataZone domain receives OpenLineage events
{%- endif %}
  Encryption:     {% if values.enableEncryption %}customer managed KMS key{% else %}keys managed by AWS{% endif %}
  Access control: {% if values.enableAccessControl %}Lake Formation{% else %}IAM policies{% endif %}
```

## What was chosen

| Setting                      | Value                                                  |
| ---------------------------- | ------------------------------------------------------ |
| Region                       | `${{ values.awsRegion }}`                              |
| Data lake                    | ${{ 'yes' if values.enableDataLake else 'no' }}        |
| Storage class                | `${{ values.dataLakeStorageClass }}`                   |
| Data catalog                 | ${{ 'yes' if values.enableDataCatalog else 'no' }}     |
| Data warehouse               | ${{ 'yes' if values.enableDataWarehouse else 'no' }}   |
| Warehouse size               | `${{ values.warehouseSize }}`                          |
| ETL pipelines                | ${{ 'yes' if values.enableEtlPipelines else 'no' }}    |
| ETL engine                   | `${{ values.etlEngine }}`                              |
| Workflow orchestration       | ${{ 'yes' if values.enableOrchestration else 'no' }}   |
| Streaming                    | ${{ 'yes' if values.enableStreaming else 'no' }}       |
| Streaming retention          | ${{ values.streamingRetention }} hours                 |
| BI integration               | ${{ 'yes' if values.enableBiTools else 'no' }}         |
| ML platform                  | ${{ 'yes' if values.enableMlPlatform else 'no' }}      |
| Encryption at rest           | ${{ 'customer managed key' if values.enableEncryption else 'keys managed by AWS' }} |
| Data lineage                 | ${{ 'yes' if values.enableDataLineage else 'no' }}     |
| Fine-grained access control  | ${{ 'yes' if values.enableAccessControl else 'no' }}   |

These are the contents of `terraform.tfvars`. Change a value there and open a pull request to change the platform. The code covers every combination, so a component can be switched on later.

## Components

- **Data lake** (`enable_data_lake`): one S3 bucket per zone, `raw`, `processed` and `curated`, versioned, private and reachable over TLS only. `data_lake_storage_class` sets the lifecycle: `standard` keeps objects in S3 Standard, `infrequent` moves them to Standard-IA after 30 days, `archive` moves them to Standard-IA after 30 days and to Glacier Instant Retrieval after 90 days. All three stay readable without a restore, so queries on old data keep working.
- **Data catalog** (`enable_data_catalog`): one Glue Data Catalog database per zone. With the data lake, a crawler per zone turns the folders of the zone's bucket into tables.
- **Data warehouse** (`enable_data_warehouse`): an Amazon Redshift cluster of `ra3.xlplus` nodes in private subnets: 2 nodes for `small`, 4 for `medium`, 8 for `large`. Redshift generates the admin password and keeps it in Secrets Manager (output `warehouse_admin_secret_arn`). Connections require TLS and are logged to CloudWatch. With the data lake and the catalog, the pipeline creates the external schema `lake_curated`, through which the warehouse queries every table of the curated zone.
- **ETL** (`enable_etl_pipelines`, `etl_engine`): two PySpark jobs from the `jobs` directory. `raw_to_processed.py` reads every dataset (top-level folder) of the raw zone, removes duplicate records and writes Parquet to the processed zone. `processed_to_curated.py` publishes the processed datasets to the curated zone and is the place for business rules. `native` runs them as AWS Glue jobs, `spark` on an EMR Serverless application; the scripts are the same.
- **Orchestration** (`enable_orchestration`): a Step Functions state machine that runs the ETL jobs, then starts the crawlers, then publishes the curated zone to the warehouse. It contains only the steps whose components are enabled and is started from the console, the API or a schedule you add.
- **Streaming** (`enable_streaming`): a Kinesis data stream in on-demand mode that keeps records for `streaming_retention_hours`. With the data lake, Firehose writes the records as compressed JSON Lines under `streaming/` in the raw zone, where the ETL jobs treat them as the dataset `streaming`.
- **BI** (`enable_bi_tools`): an Athena workgroup with a scan limit per query and the IAM role `bi`, which may run queries in that workgroup and read the curated zone. Amazon QuickSight resources cannot be created by this stack: they need a QuickSight subscription of the account, which is a paid sign-up tied to an e-mail address and an identity source the portal does not ask for. Once the account has QuickSight, create an Athena data source there with the workgroup (output `athena_workgroups`) and the role (output `bi_role_arn`); the role already trusts the QuickSight service. Other BI tools assume the role when their principal is listed in `bi_trusted_principal_arns`.
- **ML platform** (`enable_ml_platform`): a SageMaker domain with one user profile. Its execution role queries the processed and curated zones through its own Athena workgroup and keeps its files under `sagemaker/` in the artifacts bucket.
- **Encryption** (`enable_encryption`): one customer managed KMS key with yearly rotation encrypts the buckets, the Redshift cluster and its admin secret, the Kinesis stream, the Firehose output, Glue job data, logs and bookmarks, the Glue Data Catalog, Athena query results, the SageMaker domain's file system, the DataZone domain and the log groups of the pipeline and the Firehose delivery. When it is off, the same stores use the keys AWS manages for each service.
- **Data lineage** (`enable_data_lineage`): an Amazon DataZone domain, the AWS store for OpenLineage events. The ETL jobs load the OpenLineage listener that Glue 5.0 and EMR 7.5 include and send an event for every dataset they read and write (`datazone:PostLineageEvent`). Spark jobs on EMR Serverless reach the DataZone API only from a VPC, so with `etl_engine = spark` the application runs in the stack's VPC behind a NAT gateway. Without ETL the domain still accepts events other tools post to it.
- **Access control** (`enable_access_control`): the lake buckets are registered with Lake Formation, and the warehouse, BI and ML roles get Lake Formation permissions on the tables of their zones instead of IAM access to the buckets. When it is off, the same roles read the buckets of their zones through IAM policies.

The S3, KMS, VPC and IAM role building blocks are the Terraform modules of [cloud-sandbox-backstage](https://github.com/ayoinc/cloud-sandbox-backstage/tree/main/catalog/terraform-modules/aws/resources).

## How the components depend on each other

| Enabled                                   | Without                     | Result                                                                    |
| ----------------------------------------- | --------------------------- | ------------------------------------------------------------------------- |
| Data catalog                              | data lake                   | The databases exist, no crawlers                                          |
| ETL                                       | data lake                   | The jobs read and write under `zones/` in the artifacts bucket            |
| ETL                                       | data warehouse              | The pipeline ends after the crawlers                                      |
| Orchestration                             | ETL, catalog and warehouse  | No state machine, because there is no step to run                         |
| Data catalog                              | orchestration               | The crawlers run on `crawler_schedule` instead of being started by the pipeline |
| Streaming                                 | data lake                   | The data stream exists, nothing is delivered to S3                        |
| Data warehouse                            | data lake or data catalog   | The cluster exists without the external schema on the curated zone        |
| BI, ML platform                           | data lake                   | Workgroups and roles exist, with nothing in the lake to read              |
| Access control                            | data catalog                | Lake Formation is configured, but the roles read the buckets through IAM  |
| Data lineage                              | ETL                         | The DataZone domain exists and waits for events                           |

## Before the first apply

- **Account-wide settings.** With access control enabled, the stack sets the Lake Formation administrators of the account in this region to the role that applies it plus `lake_formation_admin_arns`, and new Glue databases and tables in the account are no longer granted to every IAM principal. With encryption and the catalog enabled, the Glue Data Catalog of the account in this region is encrypted with the stack's key, so every reader of the catalog needs access to that key; set `encrypt_catalog_metadata = false` to leave the catalog as it is. Use a dedicated account for the platform or check these settings with the other users of the account.
- **Streaming retention.** Kinesis keeps records for 24 hours to 365 days. A value outside that range in `terraform.tfvars` is moved to the nearest limit.
- **Costs.** The Redshift cluster, the NAT gateway (only with `etl_engine = spark` and data lineage) and the SageMaker apps users start are billed while they exist. Glue, EMR Serverless, Athena, Kinesis on-demand and Step Functions are billed by use.

## Pipeline

The **Terraform** workflow checks every push and pull request without needing an AWS account: formatting, `terraform validate`, `terraform test` against mocked providers (`tests/stack.tftest.hcl`), TFLint and a Trivy scan for high and critical findings.

Plan and apply are skipped until these are set in the repository settings:

| Setting             | Kind     | Purpose                                                 |
| ------------------- | -------- | ------------------------------------------------------- |
| `AWS_ROLE_ARN`      | secret   | IAM role the workflow assumes through GitHub OIDC       |
| `TF_STATE_BUCKET`   | variable | S3 bucket that holds the Terraform state                |
| `INFRACOST_API_KEY` | secret   | Optional. Enables the cost estimate on pushes to `main` |

Every push to `main` then produces a plan. To apply, run the workflow from the Actions tab with **Apply** ticked.

## Outputs

| Output                              | Description                                                   |
| ----------------------------------- | ------------------------------------------------------------- |
| `data_lake_buckets`                 | Bucket of each data lake zone                                 |
| `artifacts_bucket`                  | Bucket for job scripts, logs and query results                |
| `kms_key_arn`                       | Customer managed key, when encryption is enabled              |
| `catalog_databases`                 | Glue database of each zone                                    |
| `crawlers`                          | Glue crawler of each zone                                     |
| `warehouse_endpoint`                | Endpoint of the Redshift cluster                              |
| `warehouse_database`                | First database of the Redshift cluster                        |
| `warehouse_admin_secret_arn`        | Secret that holds the Redshift admin password                 |
| `etl_glue_jobs`                     | Glue jobs, for `etl_engine = native`                          |
| `etl_emr_application_id`            | EMR Serverless application, for `etl_engine = spark`          |
| `etl_role_arn`                      | IAM role the ETL jobs run with                                |
| `pipeline_state_machine_arn`        | Step Functions state machine                                  |
| `pipeline_steps`                    | Steps of the pipeline, in order                               |
| `event_stream_name`                 | Kinesis data stream                                           |
| `event_delivery_stream_name`        | Firehose stream that delivers events to the raw zone          |
| `athena_workgroups`                 | Athena workgroups of the BI tools and the ML platform         |
| `bi_role_arn`                       | IAM role BI tools assume                                      |
| `sagemaker_domain_id`               | SageMaker domain                                              |
| `sagemaker_domain_url`              | URL of the SageMaker domain                                   |
| `lineage_domain_id`                 | DataZone domain that stores data lineage                      |
| `lineage_portal_url`                | DataZone data portal                                          |
| `lake_formation_registered_buckets` | Buckets registered with Lake Formation                        |
