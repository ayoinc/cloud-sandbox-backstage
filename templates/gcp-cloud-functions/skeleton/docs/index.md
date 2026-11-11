# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds a Cloud Run function (Cloud Functions 2nd gen) and the Terraform configuration that deploys it, for the **${{ values.envName }}** environment in the project **${{ values.gcpProject }}**:

- Function `${{ values.name }}-${{ values.envName }}` in `${{ values.region }}`, runtime `${{ values.runtime }}`, built from `function/`
- Trigger: ${{ "HTTPS requests" if values.triggerType == "http" else "messages on the Pub/Sub topic `" + values.name + "-" + values.envName + "`, with retries" }}
- Dedicated runtime service account that starts with no roles
- Dedicated build service account instead of the default compute service account
- Private, versioned bucket for the source
- ${{ ("Invocations open to the internet" if values.allowUnauthenticated else "Invocations only by the IAM members you list") if values.triggerType == "http" else "Invocations only by the trigger; the function is not reachable from the internet" }}

## Configuration Summary

| Setting | Value |
| --- | --- |
| Function | `${{ values.name }}-${{ values.envName }}` |
| Project | `${{ values.gcpProject }}` |
| Region | `${{ values.region }}` |
| Runtime | `${{ values.runtime }}` |
| Trigger | `${{ values.triggerType }}` |
| Memory | `${{ values.memory }}` |
| Timeout | ${{ values.timeoutSeconds }} seconds |
| Instances | 0 to ${{ values.maxInstances }} |
| Runtime service account | `run-${{ values.name }}-${{ values.envName }}@${{ values.gcpProject }}.iam.gserviceaccount.com` |

Every setting of every environment is in `environments/*.tfvars`.

## The Function

| Path | Content |
| --- | --- |
| `function/index.js` | Registers the handler under the entry point `handler` |
| `function/src/handler.js` | The handler: start here |
| `function/test/` | Tests, run with the Node.js test runner |
| `function/package.json`, `package-lock.json` | Dependencies, pinned |

```bash
cd function
npm ci
npm test
npm start   # serves the function on http://localhost:8080
```
{% if values.triggerType == "http" %}
```bash
curl "http://localhost:8080?name=Ada"
```
{% else %}
```bash
curl localhost:8080 -X POST -H "Content-Type: application/cloudevents+json" -d '{
  "specversion": "1.0", "id": "1", "source": "//pubsub.googleapis.com/", "type": "google.cloud.pubsub.topic.v1.messagePublished",
  "data": { "message": { "messageId": "1", "data": "eyJvcmRlcklkIjo3fQ==" } }
}'
```
{% endif %}
Every push to `main` that changes `function/` produces a new source archive, and with it a new build and revision. `node_modules/` and `test/` are left out of the archive; Cloud Build installs the dependencies from `package-lock.json`.

## Invoking
{% if values.triggerType == "http" %}
{% if values.allowUnauthenticated -%}
The function accepts requests from anyone:

```bash
curl "$(terraform output -raw function_uri)?name=Ada"
```
{%- else -%}
Callers need the Cloud Run Invoker role. Add IAM members to `invokers` in `environments/${{ values.envName }}.tfvars`, apply, and call with an identity token:

```bash
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$(terraform output -raw function_uri)?name=Ada"
```

Services call the function as their service account; an identity token with the function URL as audience comes from the metadata server or the Google auth libraries. `allow_unauthenticated = true` opens the function to the internet.
{%- endif %}
{% else %}
Publish to the topic; grant publishers `roles/pubsub.publisher` on it:

```bash
gcloud pubsub topics publish ${{ values.name }}-${{ values.envName }} --project ${{ values.gcpProject }} --message '{"orderId":7}'
gcloud functions logs read ${{ values.name }}-${{ values.envName }} --project ${{ values.gcpProject }} --region ${{ values.region }} --gen2 --limit 20
```

A message is acknowledged when the handler returns and delivered again when it throws, for up to 24 hours: the handler must be safe to repeat.
{% endif %}
## Giving the Function Access

The runtime service account has no roles. List what the code needs:

```hcl
runtime_service_account_roles = ["roles/datastore.user"]

secret_environment_variables = {
  API_KEY = { secret = "orders-api-key", version = "latest" }
}
```

Secrets stay in Secret Manager; the function reads them at start, and neither this repository nor the Terraform state holds their values.

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
| Function | `npm ci` and `npm test` for the function source |
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
    | `roles/cloudfunctions.admin` | The project | Create and update the function |
    | `roles/run.admin` | The project | Set who may invoke the underlying Cloud Run service |
    | `roles/iam.serviceAccountAdmin` | The project | Create the runtime, build and trigger service accounts |
    | `roles/iam.serviceAccountUser` | The project | Deploy a function that runs and builds as those accounts |
    | `roles/resourcemanager.projectIamAdmin` | The project | Grant the build account its role, and the runtime account the roles you list |
    | `roles/storage.admin` | The project | Create the source bucket and upload the source |
    | `roles/serviceusage.serviceUsageAdmin` | The project | Enable the APIs; not needed with `enable_apis = false` |
    | `roles/pubsub.admin`, `roles/eventarc.admin` | The project | Only with the Pub/Sub trigger |
    | `roles/secretmanager.admin` | The secrets | Only with `secret_environment_variables` |
    | `roles/storage.objectUser` | The state bucket | Read and write the Terraform state |

4. Add the repository secrets:

    | Secret | Description |
    | --- | --- |
    | `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full resource name of the Workload Identity Federation provider |
    | `GCP_SERVICE_ACCOUNT` | Email of the service account the pipeline impersonates |
    | `GCP_TERRAFORM_STATE_BUCKET` | Cloud Storage bucket that holds the Terraform state |

    The provider name has the form `projects/<project-number>/locations/global/workloadIdentityPools/github/providers/${{ values.name }}`.

5. Create the GitHub environments `dev`, `staging` and `prod` under **Settings > Environments** and add required reviewers to `prod`. Apply and destroy wait for that approval.

Projects created before April 2021 also need `roles/iam.serviceAccountTokenCreator` for the Pub/Sub service agent (`service-<project-number>@gcp-sa-pubsub.iam.gserviceaccount.com`) before a Pub/Sub trigger can authenticate its deliveries.

## Variables

The settings you are most likely to change. `variables.tf` documents all of them.

| Variable | Description |
| --- | --- |
| `runtime` | Runtime, such as `nodejs24`; keep `engines` in `function/package.json` in step |
| `trigger_type` | `http` or `pubsub` |
| `available_memory`, `timeout_seconds` | Size and time limit of an invocation |
| `min_instance_count`, `max_instance_count` | Scaling; a minimum above 0 avoids cold starts |
| `allow_unauthenticated`, `invokers`, `ingress_settings` | Who and which networks reach an HTTP function |
| `environment_variables`, `secret_environment_variables` | Configuration and Secret Manager secrets |
| `runtime_service_account_roles` | Project roles of the function |

## Outputs

| Output | Description |
| --- | --- |
| `function_name` | Name of the function |
| `function_uri` | HTTPS URL of the function |
| `runtime_service_account_email` | Service account the function runs as; grant it the roles the code needs |
| `build_service_account_email` | Service account that builds the function |
| `source_bucket_name` | Bucket holding the zipped source |
| `trigger_topic_name` | Pub/Sub topic that triggers the function, or null for an HTTP function |

```bash
terraform output
terraform output -json
```

## Security

| Control | Setting |
| --- | --- |
| Identity | Dedicated runtime service account with no roles; dedicated build service account |
| Invocation | ${{ ("Public" if values.allowUnauthenticated else "IAM members in `invokers` only") if values.triggerType == "http" else "The trigger service account only; ingress limited to internal traffic" }} |
| Secrets | Secret Manager references; no values in code, configuration or state |
| Source | Private bucket with public access prevention |

### Accepted Findings

| Finding | Where | Reason |
| --- | --- | --- |
| Checkov `CKV_GCP_62` | Source bucket | It holds only the function source, which is versioned in this repository |
| Checkov `CKV_GCP_83` | Trigger topic | Messages are encrypted with Google-managed keys |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "google_storage_bucket" "main" {
  #checkov:skip=CKV_GCP_62:Reason the check does not apply
  #trivy:ignore:GCP-0066 Reason the check does not apply
}
```

## Operations

- **Logs**: `gcloud functions logs read ${{ values.name }}-${{ values.envName }} --project ${{ values.gcpProject }} --region ${{ values.region }} --gen2`. The handler writes structured JSON, so severity and fields are searchable in Cloud Logging.
- **Roll back**: revert the commit and push; the previous source is built and deployed again.
- **Upgrade the runtime**: change `runtime` in the environment files and the Node.js version in the pipeline (`NODE_VERSION`).
