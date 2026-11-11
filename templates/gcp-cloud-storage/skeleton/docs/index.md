# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds the Terraform configuration of a Cloud Storage bucket for the **${{ values.envName }}** environment in the project **${{ values.gcpProject }}**:

- Bucket `${{ values.gcpProject }}-${{ values.name }}-${{ values.envName }}` in `${{ values.bucketLocation }}`
- Uniform bucket-level access and enforced public access prevention: IAM only, never public
- Object versioning and soft delete
- Lifecycle rules for storage class transitions, expiry and previous versions
- Encryption with ${{ "a Cloud KMS key created here and rotated every 90 days" if values.encryption == "customer-managed" else "Google-managed keys, with customer-managed keys as an option" }}

## Configuration Summary

| Setting | Value |
| --- | --- |
| Bucket | `${{ values.gcpProject }}-${{ values.name }}-${{ values.envName }}` |
| Project | `${{ values.gcpProject }}` |
| Location | `${{ values.bucketLocation }}` |
| Storage class | `${{ values.storageClass }}` |
| Versioning | ${{ "Enabled" if values.versioning else "Disabled" }} |
| Encryption | ${{ "Customer-managed key (Cloud KMS)" if values.encryption == "customer-managed" else "Google-managed key" }} |
| Public access | Prevented |

Every setting of every environment is in `environments/*.tfvars`.

## Using the Bucket

Nobody has access to the objects until they are listed. Add IAM members to `object_viewers`, `object_users` or `object_admins` in `environments/${{ values.envName }}.tfvars` and apply:

```hcl
object_users   = ["serviceAccount:orders@${{ values.gcpProject }}.iam.gserviceaccount.com"]
object_viewers = ["group:analysts@<your-domain>"]
```

```bash
gcloud storage cp report.csv gs://${{ values.gcpProject }}-${{ values.name }}-${{ values.envName }}/reports/
gcloud storage ls --all-versions gs://${{ values.gcpProject }}-${{ values.name }}-${{ values.envName }}/reports/
```

Workloads authenticate as their service account; there are no keys to hand out. Signed URLs give time-limited access to a single object.

## Working Locally

```bash
# Check the configuration without touching Google Cloud
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test

# Plan against the real state
gcloud auth application-default login
terraform init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="prefix=${{ values.name }}/${{ values.envName }}"
terraform plan -var-file=environments/${{ values.envName }}.tfvars
```

The tests in `tests/` run against a mocked provider: they need no account and create nothing.

## Pipeline

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

| Job | What it does |
| --- | --- |
| Validate | `terraform fmt -check` and `terraform validate` |
| TFLint | Lints the configuration with the rules in `.tflint.hcl` |
| Terraform Tests | `terraform test` against a mocked provider |
| Security Scan | Trivy and Checkov; MEDIUM and above fail the run |
| Plan | Plans the `${{ values.envName }}` environment and attaches the plan to the run summary |
| Apply | Applies exactly that saved plan, after the approval of the GitHub environment |

The jobs before Plan need no cloud account. Plan and apply are skipped, with a notice, until the secrets below exist.

Run other environments, `destroy` (type `DESTROY` to confirm) and `drift-detection` from **Actions > Terraform > Run workflow**. Drift detection opens an issue when the deployed infrastructure no longer matches the configuration.

## Connecting the Pipeline to Google Cloud

The pipeline signs in with Workload Identity Federation: GitHub issues a short-lived token for each run and Google Cloud exchanges it for credentials of a service account. No service account key is stored anywhere.

1. Create a workload identity pool and a provider restricted to this repository:

    ```bash
    gcloud iam workload-identity-pools create github \
      --project="${{ values.gcpProject }}" --location=global

    gcloud iam workload-identity-pools providers create-oidc ${{ values.name }} \
      --project="${{ values.gcpProject }}" --location=global \
      --workload-identity-pool=github \
      --issuer-uri="https://token.actions.githubusercontent.com" \
      --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
      --attribute-condition="assertion.repository == '${{ values.destination.owner }}/${{ values.destination.repo }}'"
    ```

2. Create the service account the pipeline impersonates and let the repository use it:

    ```bash
    gcloud iam service-accounts create tf-${{ values.name }} --project="${{ values.gcpProject }}"

    gcloud iam service-accounts add-iam-policy-binding \
      "tf-${{ values.name }}@${{ values.gcpProject }}.iam.gserviceaccount.com" \
      --project="${{ values.gcpProject }}" \
      --role="roles/iam.workloadIdentityUser" \
      --member="principalSet://iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/github/attribute.repository/${{ values.destination.owner }}/${{ values.destination.repo }}"
    ```

3. Grant the service account these roles:

    | Role | Scope | Why |
    | --- | --- | --- |
    | `roles/storage.admin` | The project | Create the bucket and set its IAM policy |
    | `roles/serviceusage.serviceUsageAdmin` | The project | Enable the APIs; not needed with `enable_apis = false` |
    | `roles/cloudkms.admin` | The project | Only with customer-managed encryption |
    | `roles/storage.objectUser` | The state bucket | Read and write the Terraform state |

4. Add the repository secrets:

    | Secret | Description |
    | --- | --- |
    | `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full resource name of the Workload Identity Federation provider |
    | `GCP_SERVICE_ACCOUNT` | Email of the service account the pipeline impersonates |
    | `GCP_TERRAFORM_STATE_BUCKET` | Cloud Storage bucket that holds the Terraform state |

    The provider name has the form `projects/<project-number>/locations/global/workloadIdentityPools/github/providers/${{ values.name }}`.

5. Create the GitHub environments `dev`, `staging` and `prod` under **Settings > Environments** and add required reviewers to `prod`. Apply and destroy wait for that approval.

### Audit Logs

Who read or wrote which object is recorded by Cloud Audit Logs once data access logs are enabled for Cloud Storage in the project (**IAM & Admin > Audit Logs**, `DATA_READ` and `DATA_WRITE`). They are a project-wide setting with a cost, so this configuration leaves them to you.

## Variables

The settings you are most likely to change. `variables.tf` documents all of them.

| Variable | Description |
| --- | --- |
| `location` | Region or multi-region; fixed once the bucket exists |
| `storage_class` | Default class of new objects |
| `versioning_enabled`, `soft_delete_retention_days` | Protection against overwrites and deletions |
| `nearline_after_days`, `coldline_after_days`, `archive_after_days` | Storage class transitions by object age; `null` switches one off |
| `expire_after_days` | Deletes objects by age |
| `noncurrent_versions_to_keep`, `noncurrent_version_retention_days` | How many previous versions are kept, and for how long |
| `customer_managed_encryption`, `kms_key_name`, `kms_key_rotation_period` | Encryption with Cloud KMS |
| `object_viewers`, `object_users`, `object_admins` | Who may use the objects |
| `force_destroy` | Lets `destroy` delete a bucket that still holds objects |

## Outputs

| Output | Description |
| --- | --- |
| `bucket_name` | Name of the bucket |
| `bucket_url` | gs:// URL of the bucket |
| `bucket_self_link` | URI of the bucket in the Cloud Storage API |
| `bucket_location` | Location of the bucket |
| `kms_key_name` | Cloud KMS key that encrypts the objects, or null with Google-managed encryption |

```bash
terraform output
terraform output -json
```

## Security

| Control | Setting |
| --- | --- |
| Access | IAM only (uniform bucket-level access); public access prevention enforced |
| Encryption at rest | ${{ "Cloud KMS key, rotated every 90 days" if values.encryption == "customer-managed" else "Google-managed keys" }} |
| Recovery | Versioning and soft delete |
| Deletion | `destroy` refuses a bucket that holds objects unless `force_destroy` is set |

### Customer-Managed Encryption

With `customer_managed_encryption = true` Terraform creates a key ring and a key in the bucket location, grants the Cloud Storage service agent the right to use the key, and makes it the default key of the bucket. Key rings cannot be deleted in Google Cloud: after a destroy the ring stays behind, empty and free of charge. To use a key your security team owns instead, set `kms_key_name`; the key must be in the bucket location.

### Accepted Findings

| Finding | Where | Reason |
| --- | --- | --- |
| Checkov `CKV_GCP_62` | Bucket | Usage logs need a second bucket; access is audited with Cloud Audit Logs |
| Checkov `CKV_GCP_82` | KMS key | `prevent_destroy` would block the destroy action; destroyed key versions stay recoverable for 30 days |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "google_storage_bucket" "main" {
  #checkov:skip=CKV_GCP_62:Reason the check does not apply
  #trivy:ignore:GCP-0066 Reason the check does not apply
}
```

## Operations

- **Restore a previous version**: `gcloud storage cp gs://<bucket>/<object>#<generation> gs://<bucket>/<object>`.
- **Restore a soft-deleted object**: `gcloud storage restore gs://<bucket>/<object>#<generation>` within the retention.
- **Change the location**: not possible in place. Create a second bucket and move the data with Storage Transfer Service.
