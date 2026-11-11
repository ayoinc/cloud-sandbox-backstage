# GCP Cloud Storage Template

This template creates a repository with the Terraform configuration of a Cloud Storage bucket and a pipeline that validates and deploys it.

## What It Creates

- Cloud Storage bucket with uniform bucket-level access and enforced public access prevention
- Object versioning, soft delete and lifecycle rules for tiering, expiry and previous versions
- Optional customer-managed encryption: a Cloud KMS key ring and key with rotation, or a key you already have
- IAM bindings for the members you list

## Form Fields

| Field                      | Description                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------ |
| Bucket Name                | Name used in the bucket name, after the project ID                                   |
| Description                | Purpose of the bucket                                                                |
| Owner                      | Team that owns the resource                                                          |
| Environment                | Environment the pipeline deploys on push; variable files for all three are generated |
| GCP Region, GCP Project ID | Where the bucket is created                                                          |
| Location Type              | A bucket in the chosen region, or in the multi-region that contains it               |
| Storage Class              | Default class of new objects                                                         |
| Object Versioning          | Keep previous versions of overwritten and deleted objects                            |
| Encryption                 | Google-managed keys, or a Cloud KMS key created with the bucket                      |
| Repository Location        | GitHub repository to create                                                          |

Values chosen in the form apply to the chosen environment; the other two environment files start from defaults suited to them.

## The Generated Repository

| Path                                                       | Content                                            |
| ---------------------------------------------------------- | -------------------------------------------------- |
| `main.tf`, `variables.tf`, `outputs.tf`, `modules/`        | Terraform configuration                            |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                  |
| `tests/`                                                   | Terraform tests that run against a mocked provider |
| `.github/workflows/terraform.yaml`                         | Pipeline                                           |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml`                 | TechDocs and the catalog entity                    |

### Pipeline

The pipeline runs on pushes to `main` and passes with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov. None of these needs a Google Cloud account.

Plan and apply sign in to Google Cloud with Workload Identity Federation. They are skipped until these repository secrets exist:

| Secret                           | Description                                                     |
| -------------------------------- | --------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full resource name of the Workload Identity Federation provider |
| `GCP_SERVICE_ACCOUNT`            | Email of the service account the pipeline impersonates          |
| `GCP_TERRAFORM_STATE_BUCKET`     | Cloud Storage bucket that holds the Terraform state             |

The documentation of the generated repository explains how to create the workload identity provider, the service account, its permissions and the state bucket.

### After the First Apply

Nobody can read or write objects yet. Add IAM members to `object_viewers`, `object_users` or `object_admins` in the environment file.

## Support

Contact the Platform Team for assistance.
