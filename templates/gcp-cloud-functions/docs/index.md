# GCP Cloud Run Functions Template

This template creates a repository with a Cloud Run function (Cloud Functions 2nd gen) written for Node.js, the Terraform configuration that deploys it and a pipeline that tests and deploys both.

## What It Creates

- Function source in `function/` with tests, for an HTTP or a Pub/Sub trigger
- Cloud Run function built from that source
- Dedicated runtime service account with no roles, and a dedicated build service account
- Private, versioned bucket for the source
- For the Pub/Sub trigger: a topic and a trigger service account, the only identity allowed to invoke the function
- IAM bindings for the invokers you list, and Secret Manager access for the secrets you reference

## Form Fields

| Field                          | Description                                                                                                       |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| Function Name                  | Name of the function, before the environment; at most 18 characters because service account IDs are limited to 30 |
| Description                    | Purpose of the function                                                                                           |
| Owner                          | Team that owns the component                                                                                      |
| Environment                    | Environment the pipeline deploys on push; variable files for all three are generated                              |
| GCP Region, GCP Project ID     | Where the function runs                                                                                           |
| Runtime                        | Node.js version                                                                                                   |
| Trigger                        | HTTPS requests, or messages on a Pub/Sub topic created with the function                                          |
| Memory, Timeout, Max Instances | Size, time limit and scaling of the function                                                                      |
| Allow Public Access            | Let anyone invoke an HTTP function; off, callers need an identity and the invoker role                            |
| Repository Location            | GitHub repository to create                                                                                       |

Values chosen in the form apply to the chosen environment; the other two environment files start from defaults suited to them.

## The Generated Repository

| Path                                                       | Content                                                        |
| ---------------------------------------------------------- | -------------------------------------------------------------- |
| `main.tf`, `variables.tf`, `outputs.tf`, `modules/`        | Terraform configuration                                        |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                              |
| `tests/`                                                   | Terraform tests that run against a mocked provider             |
| `function/`                                                | Function source, tests, `package.json` and `package-lock.json` |
| `.github/workflows/terraform.yaml`                         | Pipeline                                                       |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml`                 | TechDocs and the catalog entity                                |

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

Write your logic in `function/src/handler.js`. Grant the runtime service account the roles the code needs with `runtime_service_account_roles`, and list who may call an HTTP function in `invokers`.

## Support

Contact the Platform Team for assistance.
