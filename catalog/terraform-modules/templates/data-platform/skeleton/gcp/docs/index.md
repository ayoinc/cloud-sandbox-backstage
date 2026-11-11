# ${{ values.projectName }} data platform

Google Cloud data platform for **${{ values.projectName }}** in the **${{ values.environment }}** environment, project `${{ values.gcpProjectId }}`, region `${{ values.gcpRegion }}`.

## Architecture

```text
{%- if values.enableStreaming %}
  Event producers
        |
  Pub/Sub topic (${{ values.streamingRetention }} h retention)
        |
{%- endif %}
{%- if values.enableDataLake %}
  Data lake (Cloud Storage):  raw  ->  processed  ->  curated
        |
{%- endif %}
{%- if values.enableEtlPipelines %}
{%- if values.etlEngine == 'spark' %}
  Dataproc workflow (Spark)
{%- else %}
  Dataflow pipelines
{%- endif %}
        |
{%- endif %}
{%- if values.enableDataWarehouse %}
  Data warehouse (BigQuery):  staging  ->  warehouse  ->  marts
        |
{%- endif %}
  Consumers:{% if values.enableBiTools and values.enableDataWarehouse %} Looker / Looker Studio{% endif %}{% if values.enableMlPlatform %} Vertex AI Workbench{% endif %} analysts and applications

  Around it:
{%- if values.enableOrchestration %}
    Cloud Composer (Airflow) schedules the pipelines
{%- endif %}
{%- if values.enableDataCatalog %}
    Dataplex catalogues lake and warehouse
{%- endif %}
{%- if values.enableDataLineage %}
    Data Lineage records where data comes from
{%- endif %}
    Cloud KMS: {% if values.enableEncryption %}customer-managed keys{% else %}not used, Google-managed keys{% endif %}
    IAM: {% if values.enableAccessControl %}roles per bucket and dataset{% else %}project-wide data roles{% endif %}
```

## What was chosen

| Setting                | Value                                               |
| ---------------------- | --------------------------------------------------- |
| Data lake              | ${{ 'yes' if values.enableDataLake else 'no' }}     |
| Lake storage class     | `${{ values.dataLakeStorageClass }}`                |
| Data catalog           | ${{ 'yes' if values.enableDataCatalog else 'no' }}  |
| Data warehouse         | ${{ 'yes' if values.enableDataWarehouse else 'no' }} |
| Warehouse size         | `${{ values.warehouseSize }}`                       |
| ETL/ELT pipelines      | ${{ 'yes' if values.enableEtlPipelines else 'no' }} |
| ETL engine             | `${{ values.etlEngine }}`                           |
| Workflow orchestration | ${{ 'yes' if values.enableOrchestration else 'no' }} |
| Streaming              | ${{ 'yes' if values.enableStreaming else 'no' }}    |
| Streaming retention    | ${{ values.streamingRetention }} hours              |
| BI integration         | ${{ 'yes' if values.enableBiTools else 'no' }}      |
| ML platform            | ${{ 'yes' if values.enableMlPlatform else 'no' }}   |
| Encryption at rest     | ${{ 'yes' if values.enableEncryption else 'no' }}   |
| Data lineage           | ${{ 'yes' if values.enableDataLineage else 'no' }}  |
| Fine-grained access    | ${{ 'yes' if values.enableAccessControl else 'no' }} |

These are the contents of `terraform.tfvars`. Change a value there and open a pull request to change the platform. Every setting works with every other one; a part that depends on a disabled part is left out, as described below.

## Components

- **APIs**: the Google APIs of the enabled parts are switched on. They are left on when the stack is destroyed.
- **Data lake** (`enable_data_lake`): three buckets, one per zone, named `<project name>-<environment>-<zone>-<suffix>`. The suffix is derived from the Google Cloud project ID, which keeps the globally unique names stable. Buckets are versioned, private and use uniform bucket-level access in every configuration. `data_lake_storage_class` decides what happens to ageing data: new objects are written in STANDARD, and after `data_lake_transition_days` (30) objects of the raw and processed zones move to NEARLINE (`infrequent`) or ARCHIVE (`archive`). With `standard` nothing moves. The curated zone always stays in STANDARD because queries read it.
- **Data catalog** (`enable_data_catalog`): a Dataplex lake with the zones raw, processed and curated. The lake buckets and the warehouse datasets that exist are attached as assets, and discovery registers their tables every six hours (`catalog_discovery_schedule`). An entry group and the aspect type `data-product` (owner, sensitivity) are there for sources that Dataplex does not discover. Data Catalog itself is part of Dataplex and needs no resources of its own.
- **Data warehouse** (`enable_data_warehouse`): the BigQuery datasets `staging`, `warehouse` and `marts` and an Enterprise edition reservation that the project's queries run on. `warehouse_size` sets the largest number of slots the reservation scales to: `small` 100, `medium` 200, `large` 400 (the 2, 4 and 8 nodes of the portal, at 50 slots each). No slots are paid for while no query runs, unless `warehouse_baseline_slots` is raised. Enterprise is used because Standard edition cannot query tables with customer-managed keys or policy tags. Set `assign_project_to_reservation` to `false` if another stack already assigns this project to a reservation.
- **ETL/ELT** (`enable_etl_pipelines`, `etl_engine`): a worker service account, a staging bucket and a temporary bucket (objects deleted after 7 days), in a private subnet with Cloud NAT.
    - `native` prepares Dataflow. A Dataflow job runs a Flex Template that is built from your pipeline code, so no job exists at first. Set `dataflow_flex_template_gcs_path` (and `dataflow_flex_template_parameters`) to launch one with the worker identity, subnet and buckets of this stack.
    - `spark` creates a Dataproc autoscaling policy and, when the lake is enabled, the workflow template `raw-to-processed`. Instantiating it starts a cluster, runs `jobs/raw_to_processed.py` (JSON files of the raw zone to Parquet in the processed zone) and deletes the cluster. The job is a starting point for your own.
- **Orchestration** (`enable_orchestration`): a Cloud Composer 3 environment with private networking, small outside production and medium in production. Its service account may launch the pipelines of the chosen engine. The names of buckets, datasets, the pipeline identity and the topic are available to DAGs as environment variables such as `DATA_LAKE_RAW_BUCKET` and `ETL_SERVICE_ACCOUNT`.
- **Streaming** (`enable_streaming`): a Pub/Sub topic `events` with a dead letter topic. The portal accepts 24 to 168 hours of retention; Pub/Sub itself supports 10 minutes to 31 days and a value outside that range in `terraform.tfvars` is capped, not rejected. Pub/Sub writes the events as Avro files to the raw zone when the lake is enabled and to the table `staging.events` when the warehouse is enabled. A pull subscription serves pipelines in every case.
- **BI integration** (`enable_bi_tools`): Looker Studio and Looker connect to BigQuery and need no infrastructure of their own, so this creates what makes that connection fast and safe: a BI Engine reservation (1, 2 or 4 GB for a small, medium or large warehouse) and a service account that can only read the `marts` dataset. Give the BI tool access to that service account. A dedicated Looker instance is not created because it needs an OAuth client and a licence. BI integration needs the warehouse and creates nothing without it.
- **ML platform** (`enable_ml_platform`): a Vertex AI Workbench instance without a public address that shuts down after an hour of idleness, its service account with the Vertex AI user role, and a bucket for artifacts. The service account reads the processed and curated zones and the `warehouse` and `marts` datasets. Members of `data_scientists` may open the instance.
- **Encryption** (`enable_encryption`): a Cloud KMS key ring with one key each for Cloud Storage, BigQuery and Pub/Sub, rotated every 90 days. All buckets, datasets and topics of this stack use them, and each service agent may use only its own key. Without it Google-managed keys are used. The keys are protected against deletion: to turn encryption off later, remove them from the Terraform state first. Composer's own storage and the Workbench disks use Google-managed keys in both cases.
- **Data lineage** (`enable_data_lineage`): switches on the Data Lineage API, which records BigQuery jobs by itself, gives the pipeline and Airflow identities the lineage producer role, turns on lineage reporting in Composer, in Dataproc clusters and in the Dataflow job, and lets `data_engineers` and `data_analysts` view lineage.
- **Access control** (`enable_access_control`): every identity has a profile of roles per lake zone and warehouse dataset (`governance.tf`). With access control the roles are granted on exactly those buckets and datasets, and a policy tag taxonomy (`confidential`, `pii`) restricts tagged columns to pipelines and `data_engineers`. Without it each identity gets its broadest role on the whole project and there are no policy tags. `data_engineers` and `data_analysts` are empty at first; add your groups there. The worker roles of Dataflow, Dataproc and Composer include object access in the project by Google's design, whatever this setting is.

The building blocks are the Terraform modules of [cloud-sandbox-backstage](https://github.com/ayoinc/cloud-sandbox-backstage/tree/main/catalog/terraform-modules/gcp/resources).

## Pipeline

The **Terraform** workflow checks every push and pull request without needing a Google Cloud project: formatting, `terraform validate`, `terraform test` against mocked providers (`tests/stack.tftest.hcl`), TFLint and a Trivy scan for high and critical findings.

Plan and apply are skipped until these are set in the repository settings:

| Setting                          | Kind     | Purpose                                                         |
| -------------------------------- | -------- | --------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | secret   | Workload identity provider that trusts this repository          |
| `GCP_SERVICE_ACCOUNT`            | secret   | Service account the workflow impersonates through that provider |
| `TF_STATE_BUCKET`                | variable | Cloud Storage bucket that holds the Terraform state             |
| `INFRACOST_API_KEY`              | secret   | Optional. Enables the cost estimate on pushes to `main`         |

Every push to `main` then produces a plan. To apply, run the workflow from the Actions tab with **Apply** ticked.

The Service Usage and Cloud Resource Manager APIs must be enabled in the project before the first plan.

## Outputs

| Output                       | Description                                                        |
| ---------------------------- | ------------------------------------------------------------------ |
| `lake_bucket_names`          | Bucket of each lake zone                                           |
| `dataplex_lake_name`         | Dataplex lake                                                      |
| `warehouse_dataset_ids`      | BigQuery dataset of each warehouse layer                           |
| `warehouse_reservation_name` | BigQuery slot reservation                                          |
| `etl_service_account_email`  | Identity of the pipeline workers                                   |
| `etl_bucket_names`           | Staging and temporary buckets of the pipelines                     |
| `etl_subnetwork`             | Subnet of the workers, Airflow and the Workbench instance          |
| `dataflow_job_id`            | Dataflow job, when a Flex Template is configured                   |
| `dataproc_workflow_template` | Dataproc workflow template, for `spark` with the lake              |
| `airflow_uri`                | Airflow web interface                                              |
| `airflow_dag_gcs_prefix`     | Folder that Airflow loads DAGs from                                |
| `events_topic`               | Pub/Sub topic for events                                           |
| `events_pull_subscription`   | Subscription for pipelines that read the events                    |
| `events_table`               | BigQuery table that receives the events                            |
| `bi_service_account_email`   | Read-only identity for BI tools                                    |
| `ml_service_account_email`   | Identity of the Workbench instance                                 |
| `ml_bucket_name`             | Bucket for machine learning artifacts                              |
| `workbench_proxy_uri`        | Address of JupyterLab                                              |
| `kms_key_ids`                | Customer-managed keys by service                                   |
| `policy_tag_ids`             | Policy tags for sensitive columns                                  |

An output is empty when its part is not enabled.
