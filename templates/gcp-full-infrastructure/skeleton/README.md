# ${{ values.componentName }}

${{ values.description }}

GCP infrastructure stack for `${{ values.projectName }}` (${{ values.environment }}) in project
`${{ values.gcpProjectId }}`, region `${{ values.region }}`, managed with Terraform.

## Quick start

```bash
terraform init -backend=false
terraform validate
terraform test
```

The values entered in the developer portal are in
`environments/${{ values.environment }}.tfvars`. Each resource category has its own
`.tf` file and an `enable_*` switch.

## Pipeline

`.github/workflows/terraform.yaml` validates, lints, tests and scans every
push. Plan and apply start once the repository secrets
`GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT` and
`GCP_TERRAFORM_STATE_BUCKET` exist; until then those jobs are skipped.

See [docs/index.md](docs/index.md) for the resources, the dependencies between
categories and how to enable deployments.
