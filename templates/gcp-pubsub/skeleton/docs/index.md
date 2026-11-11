# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds the Terraform configuration of a Pub/Sub topic and its subscriptions for the **${{ values.envName }}** environment in the project **${{ values.gcpProject }}**:

- Topic `${{ values.name }}-${{ values.envName }}`, storing messages only in `${{ values.region }}`
- Subscriptions: {% for subscription in values.subscriptions %}`${{ values.name }}-${{ values.envName }}-${{ subscription }}`{% if not loop.last %}, {% endif %}{% endfor %}
- Retry with exponential backoff, and subscriptions that never expire
{%- if values.deadLetter %}
- Dead-letter topic and subscription `${{ values.name }}-${{ values.envName }}-dead-letter` for messages that fail ${{ values.maxDeliveryAttempts }} times
{%- endif %}
{%- if values.schemaType != "NONE" %}
- Schema (`${{ values.schemaType }}`) that every published message must match
{%- endif %}

## Configuration Summary

| Setting | Value |
| --- | --- |
| Topic | `${{ values.name }}-${{ values.envName }}` |
| Project | `${{ values.gcpProject }}` |
| Message storage | `${{ values.region }}` |
| Topic retention | `${{ values.messageRetention }}` |
| Subscriptions | `${{ values.subscriptions | join("`, `") }}` |
| Dead letters | ${{ ("After " + values.maxDeliveryAttempts + " delivery attempts") if values.deadLetter else "Disabled" }} |
| Schema | `${{ values.schemaType }}` |

Every setting of every environment is in `environments/*.tfvars`.

## Publishing and Receiving

Nobody may publish or receive until they are listed. Add IAM members to `publishers` and `subscribers` in `environments/${{ values.envName }}.tfvars` and apply:

```hcl
publishers  = ["serviceAccount:orders@${{ values.gcpProject }}.iam.gserviceaccount.com"]
subscribers = ["serviceAccount:worker@${{ values.gcpProject }}.iam.gserviceaccount.com"]
```

```bash
gcloud pubsub topics publish ${{ values.name }}-${{ values.envName }} --project ${{ values.gcpProject }} \
  --message '{"id":"1","type":"order.created","occurred_at":"2026-01-01T00:00:00Z","data":"{}"}'

gcloud pubsub subscriptions pull ${{ values.name }}-${{ values.envName }}-${{ values.subscriptions | first }} --project ${{ values.gcpProject }} --auto-ack
```

### Subscriptions

Each entry of `subscriptions` becomes `<topic>-<key>`. Everything but the key is optional:

```hcl
subscriptions = {
  worker = {
    ack_deadline_seconds         = 60
    enable_exactly_once_delivery = true
  }
  audit = {
    filter = "attributes.type = \"audit\""
  }
  webhook = {
    push_endpoint              = "https://<service-url>/events"
    push_service_account_email = "pusher@${{ values.gcpProject }}.iam.gserviceaccount.com"
  }
}
```

A push subscription sends each message as an HTTPS request with an OIDC token of the given service account; the endpoint must verify it. The filter of a subscription cannot be changed after creation.

### Dead Letters

A message that is not acknowledged after `max_delivery_attempts` deliveries moves to `${{ values.name }}-${{ values.envName }}-dead-letter`, where it waits for 14 days. Inspect it there, fix the consumer, and publish it again:

```bash
gcloud pubsub subscriptions pull ${{ values.name }}-${{ values.envName }}-dead-letter --project ${{ values.gcpProject }} --limit 10
```

Alert on the metric `pubsub.googleapis.com/subscription/dead_letter_message_count`.

### Schema

With `schema_type` set to `AVRO` or `PROTOCOL_BUFFER`, Pub/Sub rejects messages that do not match the definition in `schemas/`. Edit the definition to describe your messages before the first apply: changing it later replaces the schema, so evolve it with compatible changes only.

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
    | `roles/pubsub.admin` | The project | Create topics, subscriptions and schemas and set their IAM policies |
    | `roles/serviceusage.serviceUsageAdmin` | The project | Enable the API; not needed with `enable_apis = false` |
    | `roles/browser` | The project | Read the project number |
    | `roles/cloudkms.admin` | The key | Only with `kms_key_name` |
    | `roles/storage.objectUser` | The state bucket | Read and write the Terraform state |

4. Add the repository secrets:

    | Secret | Description |
    | --- | --- |
    | `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full resource name of the Workload Identity Federation provider |
    | `GCP_SERVICE_ACCOUNT` | Email of the service account the pipeline impersonates |
    | `GCP_TERRAFORM_STATE_BUCKET` | Cloud Storage bucket that holds the Terraform state |

    The provider name has the form `projects/<project-number>/locations/global/workloadIdentityPools/github/providers/${{ values.name }}`.

5. Create the GitHub environments `dev`, `staging` and `prod` under **Settings > Environments** and add required reviewers to `prod`. Apply and destroy wait for that approval.



## Variables

The settings you are most likely to change. `variables.tf` documents all of them.

| Variable | Description |
| --- | --- |
| `subscriptions` | Subscriptions and their settings |
| `message_retention_duration` | Replay window of the topic, up to 31 days |
| `dead_letter_enabled`, `max_delivery_attempts` | Dead-letter handling |
| `schema_type`, `schema_definition_file`, `schema_encoding` | Message schema |
| `allowed_persistence_regions` | Regions that may store messages; the region by default |
| `kms_key_name` | Customer-managed encryption key |
| `publishers`, `subscribers` | Who may publish and receive |

## Outputs

| Output | Description |
| --- | --- |
| `topic_id` | Full resource name of the topic (projects/<project>/topics/<name>) |
| `topic_name` | Name of the topic |
| `subscription_names` | Names of the subscriptions by short name, including dead-letter when enabled |
| `dead_letter_topic_name` | Name of the dead-letter topic, or null when disabled |
| `schema_id` | Full resource name of the schema, or null without one |

```bash
terraform output
terraform output -json
```

## Security

| Control | Setting |
| --- | --- |
| Access | IAM per topic and subscription; nobody by default |
| Data residency | Messages are stored and processed only in the allowed regions |
| Push delivery | HTTPS only, authenticated with an OIDC token |
| Encryption at rest | Google-managed keys, or your key with `kms_key_name` |

### Accepted Findings

| Finding | Where | Reason |
| --- | --- | --- |
| Checkov `CKV_GCP_83` | Topics | A customer-managed key is opt-in through `kms_key_name` |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "google_storage_bucket" "main" {
  #checkov:skip=CKV_GCP_62:Reason the check does not apply
  #trivy:ignore:GCP-0066 Reason the check does not apply
}
```

## Operations

- **Replay**: seek a subscription back in time, within the retention of the topic: `gcloud pubsub subscriptions seek <subscription> --time <timestamp>`.
- **Backlog**: alert on `pubsub.googleapis.com/subscription/oldest_unacked_message_age`.
- **Remove a subscription**: delete its entry and apply; unacknowledged messages in it are lost.
