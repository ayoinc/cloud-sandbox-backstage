# ${{ values.projectName }} infrastructure

GCP three-tier web application infrastructure for **${{ values.projectName }}** (${{ values.environment }}) in project `${{ values.gcpProjectId }}`, managed with Terraform.

| Tier        | What is created                                                                 |
| ----------- | ------------------------------------------------------------------------------- |
| Network     | VPC with a subnet in `${{ values.region }}` carved from `${{ values.vpcCidr }}`, Cloud NAT, private service access |
| Web         | Global external Application Load Balancer{% if values.enableCloudArmor %} protected by Cloud Armor{% endif %}{% if values.enableCloudCdn %}, with Cloud CDN{% endif %} |
| Application | {% if values.computeType == 'gke-autopilot' %}GKE Autopilot cluster{% elif values.computeType == 'gke-standard' %}GKE Standard cluster with ${{ values.minNodes }} to ${{ values.maxNodes }} `${{ values.machineType }}` nodes{% else %}Managed instance group of ${{ values.minNodes }} to ${{ values.maxNodes }} `${{ values.machineType }}` instances{% endif %} |
| Data        | Cloud SQL ${{ 'PostgreSQL' if values.databaseEngine == 'POSTGRES' else 'MySQL' }} on `${{ values.databaseTier }}` with a private address{% if values.highAvailability %}, highly available{% endif %} |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description is in [`docs/index.md`](docs/index.md).

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans every compute type against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to the Google Cloud project and stay skipped until it is configured:

| Setting                          | Kind     | Purpose                                                         |
| -------------------------------- | -------- | --------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | secret   | Workload identity provider that trusts this repository          |
| `GCP_SERVICE_ACCOUNT`            | secret   | Service account the workflow acts as                            |
| `TF_STATE_BUCKET`                | variable | Cloud Storage bucket that holds the Terraform state             |
| `INFRACOST_API_KEY`              | secret   | Optional. Enables the cost estimate on pushes to `main`         |

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked.

## Working locally

```bash
terraform init -backend-config="bucket=<state bucket>"
terraform plan
```

Use `terraform init -backend=false` to validate without access to the state bucket.
