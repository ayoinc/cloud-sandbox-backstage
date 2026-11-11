# ${{ values.name }}

${{ values.description }}

A [Terragrunt](https://terragrunt.com) live repository for {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %}: what is deployed where, per environment and region. Terragrunt runs [OpenTofu](https://opentofu.org).

## Layout

```
root.hcl                         Remote state, provider and common inputs for every unit
live/
  <environment>/
    env.hcl                      Settings of the environment
    <region>/
      region.hcl                 The region
      terragrunt.stack.hcl       The units deployed here and their values
catalog/
  units/<unit>/terragrunt.hcl    A unit: one module, its inputs and its dependencies
  modules/<module>/              The OpenTofu module a unit deploys, with tests
mise.toml                        Pinned OpenTofu and Terragrunt versions
```

A **unit** is one module with one state. A **stack** (`terragrunt.stack.hcl`) lists the units of one environment and region; Terragrunt generates them into `.terragrunt-stack/`, which is not committed. The directory a unit is generated into decides its state key, its region and its environment, because `root.hcl` reads `env.hcl` and `region.hcl` from the parent directories.

## Units
{%- if values.cloud == 'aws' %}

| Unit | Module | Creates |
| --- | --- | --- |
| `foundation` | `catalog/modules/foundation` | Rotating KMS key and its alias |
| `storage` | `catalog/modules/storage` | Log bucket: versioned, private, TLS only, encrypted with the key of `foundation` |
{%- elif values.cloud == 'azure' %}

| Unit | Module | Creates |
| --- | --- | --- |
| `foundation` | `catalog/modules/foundation` | Resource group |
| `storage` | `catalog/modules/storage` | Log storage account in the resource group of `foundation`: Entra ID sign-in only, firewall closed by default, versioned, doubly encrypted |
{%- else %}

| Unit | Module | Creates |
| --- | --- | --- |
| `foundation` | `catalog/modules/foundation` | Cloud KMS key ring and rotating key that Cloud Storage may use |
| `storage` | `catalog/modules/storage` | Log bucket: versioned, public access prevented, encrypted with the key of `foundation` |
{%- endif %}

`storage` declares a `dependency` on `foundation`, so Terragrunt applies them in order and passes the outputs along.

## Working Locally

```bash
mise install                 # OpenTofu and Terragrunt in the versions of mise.toml

terragrunt hcl fmt           # format every .hcl file
cd live
terragrunt run --all --feature offline=true -- validate
```

The `offline` feature flag in `root.hcl` swaps the remote backend for a local one, so validation needs no credentials. To test the modules:

```bash
tofu -chdir=catalog/modules/storage init -backend=false
tofu -chdir=catalog/modules/storage test
```

To plan against real state, sign in to {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %} and set what the pipeline would set:

```bash
{% if values.cloud == 'aws' %}export STATE_BUCKET=<state-bucket>{% elif values.cloud == 'azure' %}export ARM_SUBSCRIPTION_ID=<subscription-id>
export STATE_STORAGE_ACCOUNT=<storage-account>{% else %}export GOOGLE_PROJECT=<project-id>
export STATE_BUCKET=<state-bucket>{% endif %}

cd live/dev
terragrunt run --all -- plan
```

After an offline run, add `-reconfigure` to the first `init` so that OpenTofu switches back to the remote backend: `terragrunt run --all -- init -reconfigure`.

Useful commands:

| Command | Effect |
| --- | --- |
| `terragrunt stack generate` | Write the units of the stack in the current directory to `.terragrunt-stack/` |
| `terragrunt run --all -- plan` | Plan every unit below the current directory in dependency order |
| `terragrunt stack output` | Outputs of every unit of the stack |
| `terragrunt dag graph` | Dependency graph of the units |

## Pipeline

| Trigger | What runs |
| --- | --- |
| Push to `main` | Format check, validation of every unit, module tests, Trivy scan, then plan and apply of `dev` |
| Manual run | The same checks, then `plan` or `apply` of the chosen environment |

Plan and apply are skipped until the target GitHub environment has its variables. Apply plans again before it changes anything; the plan job shows what to expect.

### GitHub Environments

Create the environments `dev`, `staging` and `prod` under Settings → Environments. The pipeline signs in with OIDC, so there is no secret to store; add these **environment variables** to each one, so that every environment can use its own account, identity and state bucket:
{%- if values.cloud == 'aws' %}

| Variable | Value |
| --- | --- |
| `AWS_ROLE_ARN` | Role in the account of this environment that the pipeline assumes through the GitHub OIDC provider |
| `STATE_BUCKET` | S3 bucket in that account that holds the state |
| `AWS_REGION` | Optional: region to sign in to; defaults to `${{ values.region }}` |

The bucket must exist, be versioned and block public access; state locking uses a lock object in the bucket, so no DynamoDB table is needed. Terragrunt can create it for you: run `terragrunt backend bootstrap` in a unit directory with administrator credentials.

Let each role trust `token.actions.githubusercontent.com` for the subject `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:environment:<environment>` only, and grant it what the units manage (KMS and S3) plus read and write access to the state bucket.
{%- elif values.cloud == 'azure' %}

| Variable | Value |
| --- | --- |
| `AZURE_CLIENT_ID` | Application (client) ID of the identity the pipeline signs in as |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription of this environment |
| `STATE_STORAGE_ACCOUNT` | Storage account that holds the state, in a `tfstate` container |

Add a federated credential to the identity for the subject `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:environment:<environment>`. Grant it `Contributor` on the subscription and `Storage Blob Data Contributor` on the state container; the state backend signs in with Entra ID, so the storage account needs no shared key.
{%- else %}

| Variable | Value |
| --- | --- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Resource name of the workload identity provider: `projects/<number>/locations/global/workloadIdentityPools/<pool>/providers/<provider>` |
| `GCP_SERVICE_ACCOUNT` | Email of the service account the pipeline impersonates |
| `GCP_PROJECT_ID` | Project of this environment |
| `STATE_BUCKET` | Cloud Storage bucket that holds the state |

Restrict the workload identity provider to this repository with the attribute condition `assertion.repository == '${{ values.destination.owner }}/${{ values.destination.repo }}'`. Grant the service account `roles/cloudkms.admin` and `roles/storage.admin` in the project and `roles/storage.objectUser` on the state bucket, and enable `cloudkms.googleapis.com` and `storage.googleapis.com`.
{%- endif %}

Restrict all three environments to the `main` branch. Required reviewers on an environment gate its plan as well as its apply.

## Common Changes

**Change a setting of one environment.** Edit `live/<environment>/env.hcl`, or the `values` of a unit in its `terragrunt.stack.hcl`.

**Add a region.** Copy `live/<environment>/<region>/` to a directory named after the new region and change `region.hcl`.

**Add a unit.** Add the module to `catalog/modules/`, a unit to `catalog/units/` and a `unit` block to each `terragrunt.stack.hcl` that should deploy it.

**Version the catalog.** Units and modules are referenced by path, so every environment follows `main`. To promote changes one environment at a time, move `catalog/` to its own repository and reference it by tag: `source = "git::https://github.com/<owner>/<catalog>.git//units/storage?ref=v1.0.0"`.

## Owner

This repository is owned by **${{ values.owner }}**.
