# ${{ values.projectName }} data platform

Google Cloud data platform for **${{ values.projectName }}** (${{ values.environment }}) in project `${{ values.gcpProjectId }}`, region `${{ values.gcpRegion }}`, managed with Terraform.

| Part | What is created |
| ---- | --------------- |
| Data lake | {% if values.enableDataLake %}Cloud Storage buckets for the raw, processed and curated zones{% if values.dataLakeStorageClass == 'infrequent' %}; ageing raw and processed objects move to NEARLINE{% elif values.dataLakeStorageClass == 'archive' %}; ageing raw and processed objects move to ARCHIVE{% endif %}{% else %}Not enabled{% endif %} |
| Data catalog | {% if values.enableDataCatalog %}Dataplex lake with a zone per lake zone and metadata discovery{% else %}Not enabled{% endif %} |
| Data warehouse | {% if values.enableDataWarehouse %}BigQuery datasets `staging`, `warehouse` and `marts` on an Enterprise reservation of up to {% if values.warehouseSize == 'small' %}100{% elif values.warehouseSize == 'medium' %}200{% else %}400{% endif %} slots{% else %}Not enabled{% endif %} |
| ETL/ELT | {% if values.enableEtlPipelines %}{% if values.etlEngine == 'spark' %}Dataproc: worker identity, staging and temporary buckets, private network and an autoscaling policy{% if values.enableDataLake %}, plus a workflow template that runs a PySpark job on a cluster it creates for the run{% endif %}{% else %}Dataflow: worker identity, staging and temporary buckets and private network, ready for a Flex Template{% endif %}{% else %}Not enabled{% endif %} |
| Orchestration | {% if values.enableOrchestration %}Cloud Composer 3 environment (Airflow) with private networking{% else %}Not enabled{% endif %} |
| Streaming | {% if values.enableStreaming %}Pub/Sub topic that keeps events for ${{ values.streamingRetention }} hours{% if values.enableDataLake and values.enableDataWarehouse %} and writes them to the raw zone and to the warehouse{% elif values.enableDataLake %} and writes them to the raw zone{% elif values.enableDataWarehouse %} and writes them to the warehouse{% endif %}, with a pull subscription for pipelines{% else %}Not enabled{% endif %} |
| BI | {% if values.enableBiTools %}{% if values.enableDataWarehouse %}BI Engine reservation and a read-only identity for Looker or Looker Studio{% else %}Chosen, but it needs the data warehouse, which is not enabled{% endif %}{% else %}Not enabled{% endif %} |
| Machine learning | {% if values.enableMlPlatform %}Vertex AI Workbench instance with its identity and artifact bucket{% else %}Not enabled{% endif %} |
| Encryption | {% if values.enableEncryption %}Customer-managed Cloud KMS keys for buckets, BigQuery and Pub/Sub{% else %}Google-managed keys{% endif %} |
| Data lineage | {% if values.enableDataLineage %}Data Lineage API, reported to by the pipelines{% else %}Not enabled{% endif %} |
| Access control | {% if values.enableAccessControl %}Roles per bucket and dataset{% if values.enableDataWarehouse %}, policy tags for sensitive columns{% endif %}{% else %}Project-wide data roles{% endif %} |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description is in [`docs/index.md`](docs/index.md).

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans the feature combinations against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to the Google Cloud project and stay skipped until it is configured:

| Setting                          | Kind     | Purpose                                                           |
| -------------------------------- | -------- | ----------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | secret   | Workload identity provider that trusts this repository            |
| `GCP_SERVICE_ACCOUNT`            | secret   | Service account the workflow impersonates through that provider   |
| `TF_STATE_BUCKET`                | variable | Cloud Storage bucket that holds the Terraform state               |
| `INFRACOST_API_KEY`              | secret   | Optional. Enables the cost estimate on pushes to `main`           |

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked.

The service account needs to manage the services of this stack in `${{ values.gcpProjectId }}`, including enabling APIs and granting IAM roles. The Service Usage and Cloud Resource Manager APIs must already be enabled in the project.

## Working locally

```bash
terraform init -backend-config="bucket=<state bucket>"
terraform plan
```

Use `terraform init -backend=false` to validate without access to the state bucket.
