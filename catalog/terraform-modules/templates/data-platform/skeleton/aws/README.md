# ${{ values.projectName }} data platform

AWS data platform for **${{ values.projectName }}** (${{ values.environment }}) in `${{ values.awsRegion }}`, managed with Terraform.

| Component      | What is created                                                                 |
| -------------- | ------------------------------------------------------------------------------- |
| Data lake      | {% if values.enableDataLake %}S3 buckets for the raw, processed and curated zones, `${{ values.dataLakeStorageClass }}` lifecycle{% else %}not enabled{% endif %} |
| Data catalog   | {% if values.enableDataCatalog %}Glue Data Catalog database per zone{% if values.enableDataLake %} and a crawler per zone{% endif %}{% else %}not enabled{% endif %} |
| Data warehouse | {% if values.enableDataWarehouse %}Amazon Redshift cluster, size `${{ values.warehouseSize }}`{% else %}not enabled{% endif %} |
| ETL            | {% if values.enableEtlPipelines %}{% if values.etlEngine == 'native' %}Two AWS Glue jobs{% else %}EMR Serverless application running two Spark jobs{% endif %} (raw to processed, processed to curated){% else %}not enabled{% endif %} |
| Orchestration  | {% if values.enableOrchestration %}Step Functions state machine that runs the pipeline{% else %}not enabled{% endif %} |
| Streaming      | {% if values.enableStreaming %}Kinesis data stream keeping records for ${{ values.streamingRetention }} hours{% if values.enableDataLake %}, delivered to the raw zone by Firehose{% endif %}{% else %}not enabled{% endif %} |
| BI             | {% if values.enableBiTools %}Athena workgroup and an IAM role for QuickSight and other BI tools{% else %}not enabled{% endif %} |
| ML platform    | {% if values.enableMlPlatform %}SageMaker domain with access to the processed and curated zones{% else %}not enabled{% endif %} |
| Encryption     | {% if values.enableEncryption %}Customer managed KMS key on every store{% else %}Keys managed by AWS{% endif %} |
| Data lineage   | {% if values.enableDataLineage %}Amazon DataZone domain that receives OpenLineage events from the ETL jobs{% else %}not enabled{% endif %} |
| Access control | {% if values.enableAccessControl %}Lake Formation permissions on the tables of each zone{% else %}IAM policies on the buckets of each zone{% endif %} |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description, including how the components depend on each other and what to know before the first apply, is in [`docs/index.md`](docs/index.md).

## Layout

| File                 | Contents                                                     |
| -------------------- | ------------------------------------------------------------ |
| `main.tf`            | KMS key, IAM roles, VPC and the artifacts bucket             |
| `lake.tf`            | Data lake buckets and their lifecycle                        |
| `catalog.tf`         | Glue databases, crawlers and Glue encryption settings        |
| `warehouse.tf`       | Redshift cluster                                             |
| `etl.tf`             | Glue jobs or the EMR Serverless application                  |
| `orchestration.tf`   | Step Functions state machine                                 |
| `streaming.tf`       | Kinesis data stream and Firehose delivery                    |
| `analytics.tf`       | Athena workgroups, BI role and SageMaker domain              |
| `governance.tf`      | Lake Formation access control and the DataZone lineage domain |
| `jobs/`              | PySpark scripts of the two ETL stages                        |
| `tests/`             | `terraform test` runs against mocked providers               |

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans the combinations of components against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to an AWS account and stay skipped until it is configured:

| Setting             | Kind     | Purpose                                                   |
| ------------------- | -------- | --------------------------------------------------------- |
| `AWS_ROLE_ARN`      | secret   | IAM role the workflow assumes through GitHub OIDC         |
| `TF_STATE_BUCKET`   | variable | S3 bucket that holds the Terraform state                  |
| `INFRACOST_API_KEY` | secret   | Optional. Enables the cost estimate on pushes to `main`   |

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked.

## Working locally

```bash
terraform init -backend-config="bucket=<state bucket>"
terraform plan
```

Use `terraform init -backend=false` to validate and test without access to the state bucket.
