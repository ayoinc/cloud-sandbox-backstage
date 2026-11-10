# ${{ values.componentName }}

${{ values.description }}

Terraform configuration for the **${{ values.environment }}** environment of
`${{ values.projectName }}` in GCP project `${{ values.gcpProjectId }}`
(region `${{ values.region }}`). Owner: `${{ values.owner }}`.

## What is created

Each category is switched on or off in `environments/${{ values.environment }}.tfvars`.

| Category   | Switch              | Selected | Resources |
| ---------- | ------------------- | -------- | --------- |
| Networking | `enable_networking` | ${{ values.enable_networking }} | VPC network, subnets with flow logs, Cloud Router and Cloud NAT per region, firewall rules (internal, IAP SSH, health checks) |
| Compute    | `enable_compute`    | ${{ values.enable_compute }} | Service account, shielded instance template without public address, regional managed instance group |
| Containers | `enable_containers` | ${{ values.enable_containers }} | Private GKE cluster with Workload Identity, autoscaled node pool, Artifact Registry repository |
| Storage    | `enable_storage`    | ${{ values.enable_storage }} | Data bucket and access log bucket; Filestore when `enable_filestore` is set |
| Database   | `enable_database`   | ${{ values.enable_database }} | Cloud SQL with a private address, database, user, password in Secret Manager; Firestore and Memorystore Redis when their switches are set |
| Security   | `enable_security`   | ${{ values.enable_security }} | Cloud KMS key (encrypts the buckets and the BigQuery dataset), application service account, Secret Manager secret |
| Monitoring | `enable_monitoring` | ${{ values.enable_monitoring }} | Log-based error metric, alert policy, optional email notification channel |
| Analytics  | `enable_analytics`  | ${{ values.enable_analytics }} | BigQuery dataset, Pub/Sub topic and subscription |
| AI/ML      | `enable_ai_ml`      | ${{ values.enable_ai_ml }} | Vertex AI API, service account, artifact bucket |
| Serverless | `enable_serverless` | ${{ values.enable_serverless }} | Cloud Run service reachable from the VPC and load balancers only |

The APIs each category needs are enabled by Terraform. Every resource name
starts with `${{ values.projectName }}-${{ values.environment }}`.

### Dependencies between categories

- With networking off, the other categories use the existing network and
  subnetwork named by `existing_network` and `existing_subnetwork`
  (`default` unless changed).
- Cloud SQL and Memorystore Redis reach the network through private service
  access. Terraform reserves the range and creates the peering; set
  `create_private_service_access = false` if the network is already peered.
- The GKE nodes use the last /20 of `network_cidr`. Keep your own subnets out
  of that range or set `gke_subnet_cidr`.
- `prod` and `dr` environments get deletion protection, a regional Cloud SQL
  instance and a highly available Redis tier.

## Repository layout

| Path | Purpose |
| ---- | ------- |
| `*.tf` | One file per category (`networking.tf`, `compute.tf`, ...) plus `variables.tf`, `locals.tf` and `outputs.tf` |
| `environments/${{ values.environment }}.tfvars` | The values entered in the developer portal |
| `tests/infrastructure.tftest.hcl` | Terraform tests that run against mocked providers |
| `.github/workflows/terraform.yaml` | Validation, security scans, plan and apply |

## Pipeline

The `Terraform` workflow runs on every push and pull request.

| Job | Needs credentials | What it does |
| --- | ----------------- | ------------ |
| Validate | No | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` |
| TFLint | No | Lints the configuration with the Google ruleset |
| Terraform tests | No | `terraform test` with mocked providers |
| Security scan (Trivy) | No | Fails on critical, high and medium misconfigurations |
| Security scan (Checkov) | No | Policy checks for the Terraform code |
| Cost estimation | `INFRACOST_API_KEY` | Comments the cost estimate on pull requests |
| Plan / Apply | GCP secrets | Plans on pull requests, applies on pushes to `main` |
| Destroy / Drift detection | GCP secrets | Started manually from the Actions tab |

Jobs that need credentials are skipped until the secrets exist, so a new
repository is green before any cloud access is configured.

### Enabling plan and apply

1. Create a Cloud Storage bucket for the Terraform state.
2. Create a Workload Identity Federation provider for GitHub Actions and a
   service account that this repository may impersonate. Grant the service
   account the roles needed to manage the enabled categories.
3. Add the repository secrets:

| Secret | Value |
| ------ | ----- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/<number>/locations/global/workloadIdentityPools/<pool>/providers/<provider>` |
| `GCP_SERVICE_ACCOUNT` | Email of the service account |
| `GCP_TERRAFORM_STATE_BUCKET` | Name of the state bucket |
| `INFRACOST_API_KEY` | Optional, enables cost estimates |

To require an approval before applies, add required reviewers to the
`${{ values.environment }}` environment in the repository settings.

## Working locally

```bash
terraform init -backend=false
terraform validate
terraform test

# With access to the state bucket
terraform init -backend-config="bucket=<state bucket>" -backend-config="prefix=${{ values.componentName }}/${{ values.environment }}"
terraform plan -var-file=environments/${{ values.environment }}.tfvars
```

## Security decisions

- No instance, node or database has a public address. Outbound traffic uses
  Cloud NAT and SSH goes through Identity-Aware Proxy.
- Buckets enforce uniform access and public access prevention.
- Artifact Registry and Pub/Sub use Google-managed encryption. Using the
  Cloud KMS key there needs a grant to their service agents first.
- Google Groups for GKE RBAC is off until `gke_rbac_security_group` is set,
  because it needs a Google Workspace group.
