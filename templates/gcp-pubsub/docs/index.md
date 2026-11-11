# GCP Pub/Sub Template

This template creates a repository with the Terraform configuration of a Pub/Sub topic and its subscriptions, and a pipeline that validates and deploys it.

## What It Creates

- Pub/Sub topic with message retention and a storage policy restricted to the chosen region
- Pull subscriptions (push with OIDC authentication is one setting away) with retry backoff and no expiry
- Dead-letter topic and subscription, with the grants the Pub/Sub service agent needs
- Optional Avro or Protocol Buffers schema that published messages must match
- IAM bindings for the publishers and subscribers you list

## Form Fields

| Field                      | Description                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------ |
| Topic Name                 | Name of the topic, before the environment                                            |
| Description                | Purpose of the topic                                                                 |
| Owner                      | Team that owns the resource                                                          |
| Environment                | Environment the pipeline deploys on push; variable files for all three are generated |
| GCP Region, GCP Project ID | Where messages are stored                                                            |
| Subscriptions              | Short names of the subscriptions to create                                           |
| Topic Message Retention    | How far back subscriptions can replay                                                |
| Dead-Letter Topic          | Park messages that keep failing instead of redelivering them forever                 |
| Max Delivery Attempts      | Attempts before a message is parked                                                  |
| Message Schema             | None, Avro or Protocol Buffers; a starting definition is generated in `schemas/`     |
| Repository Location        | GitHub repository to create                                                          |

Values chosen in the form apply to the chosen environment; the other two environment files start from defaults suited to them.

## The Generated Repository

| Path                                                       | Content                                            |
| ---------------------------------------------------------- | -------------------------------------------------- |
| `main.tf`, `variables.tf`, `outputs.tf`, `modules/`        | Terraform configuration                            |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                  |
| `tests/`                                                   | Terraform tests that run against a mocked provider |
| `schemas/`                                                 | Message schema definitions                         |
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

Nobody can publish or receive yet. Add IAM members to `publishers` and `subscribers` in the environment file. If you chose a schema, edit the definition in `schemas/` before the first apply.

## Support

Contact the Platform Team for assistance.
