# ${{ values.name }}

${{ values.description }}

A [Pulumi](https://www.pulumi.com) project in Python for {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %} with one stack per environment: `dev`, `staging` and `prod`.

## Layout

| Path | Content |
| --- | --- |
| `__main__.py` | The program: reads the configuration and creates the resources |
| `components/log_store.py` | The `LogStore` component |
| `tests/` | Unit tests that run against a mocked engine |
| `Pulumi.yaml` | Project settings and the configuration schema |
| `Pulumi.dev.yaml`, `Pulumi.staging.yaml`, `Pulumi.prod.yaml` | Configuration per stack |
| `pyproject.toml` | Dependencies and tool settings; managed with [uv](https://docs.astral.sh/uv/) |
| `.github/workflows/pulumi.yaml` | Pipeline |

## What It Creates
{%- if values.cloud == 'aws' %}

`LogStore` is a component resource: a private S3 bucket for logs that is versioned, refuses requests without TLS, is encrypted with its own rotating KMS key and expires objects after the retention period.
{%- elif values.cloud == 'azure' %}

`LogStore` is a component resource: a resource group with a storage account for logs that accepts Entra ID sign-in only, refuses public blob access, has its firewall closed by default, is versioned and doubly encrypted, and expires blobs after the retention period.
{%- else %}

`LogStore` is a component resource: a private Cloud Storage bucket for logs that is versioned, prevents public access, is encrypted with its own rotating Cloud KMS key and expires objects after the retention period.
{%- endif %}

## Configuration

| Key | Default | Description |
| --- | --- | --- |
| `logRetentionDays` | `90` | Days that log objects are kept; at least 30 |
| `forceDestroy` | `false` | Allow the log storage to be destroyed while it holds objects |

Set a value for one stack with `pulumi config set logRetentionDays 180 --stack <org>/staging`; it is written to `Pulumi.staging.yaml`. Secrets go in with `--secret` and are stored encrypted.

## Working Locally

```bash
uv sync              # creates .venv and uv.lock; commit uv.lock
uv run ruff check .
uv run ruff format --check .
uv run mypy .
uv run pytest        # unit tests; no credentials needed
```

Pulumi runs the program in the environment uv manages:

```bash
pulumi stack select <org>/dev --create
pulumi preview
```

{% if values.cloud == 'aws' %}Sign in to AWS (`aws sso login`){% elif values.cloud == 'azure' %}Sign in to Azure (`az login`) and export `ARM_SUBSCRIPTION_ID`{% else %}Sign in to Google Cloud (`gcloud auth application-default login`) and export `GOOGLE_PROJECT`{% endif %} before the preview.

## Tests

The tests in `tests/` replace the Pulumi engine with mocks (`pulumi.runtime.set_mocks`): resources are echoed back instead of created, and the tests assert on the properties of the resources the component exposes. Add a test for every rule the component must keep.

## Pipeline

| Trigger | What runs |
| --- | --- |
| Push to `main` | Ruff, mypy and unit tests, then preview and update of `dev` |
| Manual run | The same checks, then `preview` or `up` of the chosen stack |

Preview and update are skipped until the repository variables below exist. Updates run in the GitHub environment named after the stack; add required reviewers to `staging` and `prod` under Settings → Environments.

### Repository Variables

The pipeline signs in to Pulumi Cloud and to {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %} with OIDC, so there is no secret to store. Add these under Settings → Secrets and variables → Actions → Variables:
{%- if values.cloud == 'aws' %}

| Variable | Value |
| --- | --- |
| `PULUMI_ORG` | Pulumi organisation that owns the stacks |
| `AWS_ROLE_ARN` | Role the pipeline assumes through the GitHub OIDC provider |
| `AWS_REGION` | Optional: region to sign in to; defaults to `${{ values.region }}` |

Let the role trust `token.actions.githubusercontent.com` for `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:*` only, and grant it what the program manages: S3 buckets and KMS keys.
{%- elif values.cloud == 'azure' %}

| Variable | Value |
| --- | --- |
| `PULUMI_ORG` | Pulumi organisation that owns the stacks |
| `AZURE_CLIENT_ID` | Application (client) ID of the identity the pipeline signs in as |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription the stacks are deployed to |

Add a federated credential to the identity for each subject the pipeline runs as: `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:ref:refs/heads/main` for previews, and `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:environment:dev` (then `staging` and `prod`) for updates. Grant it `Contributor` on the subscription.
{%- else %}

| Variable | Value |
| --- | --- |
| `PULUMI_ORG` | Pulumi organisation that owns the stacks |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Resource name of the workload identity provider: `projects/<number>/locations/global/workloadIdentityPools/<pool>/providers/<provider>` |
| `GCP_SERVICE_ACCOUNT` | Email of the service account the pipeline impersonates |
| `GCP_PROJECT_ID` | Project the stacks are deployed to |

Restrict the workload identity provider to this repository with the attribute condition `assertion.repository == '${{ values.destination.owner }}/${{ values.destination.repo }}'`. Grant the service account `roles/storage.admin` and `roles/cloudkms.admin` in the project and enable `cloudkms.googleapis.com` and `storage.googleapis.com`.
{%- endif %}

In Pulumi Cloud, register GitHub as an OIDC issuer (Settings → OIDC Issuers, URL `https://token.actions.githubusercontent.com`) with a policy that issues an organisation token to `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:*`.

## Pulumi ESC

[Pulumi ESC](https://www.pulumi.com/docs/esc/) can hold the configuration and hand out short-lived cloud credentials, so that the pipeline and every engineer get them from one place. Create an environment per stack:
{%- if values.cloud == 'aws' %}

```yaml
# esc env init <org>/${{ values.name }}/dev, then esc env edit <org>/${{ values.name }}/dev
values:
  aws:
    login:
      fn::open::aws-login:
        oidc:
          roleArn: <role-arn>
          sessionName: pulumi-${{ values.name }}-dev
  environmentVariables:
    AWS_ACCESS_KEY_ID: ${aws.login.accessKeyId}
    AWS_SECRET_ACCESS_KEY: ${aws.login.secretAccessKey}
    AWS_SESSION_TOKEN: ${aws.login.sessionToken}
  pulumiConfig:
    aws:region: ${{ values.region }}
    ${{ values.name }}:logRetentionDays: 30
```

The role trusts the Pulumi Cloud OIDC issuer (`api.pulumi.com/oidc`) instead of GitHub.
{%- elif values.cloud == 'azure' %}

```yaml
# esc env init <org>/${{ values.name }}/dev, then esc env edit <org>/${{ values.name }}/dev
values:
  azure:
    login:
      fn::open::azure-login:
        clientId: <client-id>
        tenantId: <tenant-id>
        subscriptionId: <subscription-id>
        oidc: true
  environmentVariables:
    ARM_USE_OIDC: "true"
    ARM_CLIENT_ID: ${azure.login.clientId}
    ARM_TENANT_ID: ${azure.login.tenantId}
    ARM_SUBSCRIPTION_ID: ${azure.login.subscriptionId}
    ARM_OIDC_TOKEN: ${azure.login.oidc.token}
  pulumiConfig:
    azure-native:location: ${{ values.region }}
    ${{ values.name }}:logRetentionDays: 30
```

The identity gets a federated credential for the Pulumi Cloud OIDC issuer (`https://api.pulumi.com/oidc`) instead of GitHub.
{%- else %}

```yaml
# esc env init <org>/${{ values.name }}/dev, then esc env edit <org>/${{ values.name }}/dev
values:
  gcp:
    login:
      fn::open::gcp-login:
        project: <project-number>
        oidc:
          workloadPoolId: <pool>
          providerId: <provider>
          serviceAccount: <service-account-email>
  environmentVariables:
    GOOGLE_OAUTH_ACCESS_TOKEN: ${gcp.login.accessToken}
    GOOGLE_PROJECT: <project-id>
  pulumiConfig:
    gcp:region: ${{ values.region }}
    ${{ values.name }}:logRetentionDays: 30
```

The workload identity provider trusts the Pulumi Cloud OIDC issuer (`https://api.pulumi.com/oidc`) instead of GitHub.
{%- endif %}

Then import it at the top of the stack file and delete the values it now provides:

```yaml
# Pulumi.dev.yaml
environment:
  - ${{ values.name }}/dev
```

With credentials coming from ESC, the cloud sign-in of the workflow and its repository variables can be removed; `PULUMI_ORG` stays.

## Owner

This project is owned by **${{ values.owner }}**.
