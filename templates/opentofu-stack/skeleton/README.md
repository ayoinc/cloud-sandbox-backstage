# ${{ values.name }}

${{ values.description }}

An [OpenTofu](https://opentofu.org) root stack for {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %} with three environments. State and plan files are encrypted on the client before they are stored.

## Layout

| Path | Content |
| --- | --- |
| `versions.tofu`, `providers.tofu` | OpenTofu and provider versions, provider configuration |
| `backend.tofu` | State backend; one state object per environment |
| `encryption.tofu` | Client-side encryption of state and plan files |
| `main.tofu`, `network.tofu`, `storage.tofu` | The resources |
| `variables.tofu`, `outputs.tofu` | Inputs and outputs |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | Values per environment |
| `tests/` | Tests that run against a mocked provider |
| `.github/workflows/opentofu.yaml` | Pipeline |

## What It Creates
{%- if values.cloud == 'aws' %}

| File | Resources |
| --- | --- |
| `network.tofu` | VPC, private subnets across availability zones, a closed default security group, VPC flow logs |
| `storage.tofu` | Log bucket: versioned, private, TLS only, encrypted with its own rotating KMS key, with expiry rules |
{%- elif values.cloud == 'azure' %}

| File | Resources |
| --- | --- |
| `main.tofu` | Resource group, with an optional delete lock |
| `network.tofu` | Virtual network, private subnet without default outbound access, network security group |
| `storage.tofu` | Log storage account: Entra ID sign-in only, firewall closed by default, versioned, doubly encrypted, with expiry rules |
{%- else %}

| File | Resources |
| --- | --- |
| `network.tofu` | VPC network, private subnet with flow logs and Private Google Access, optional Cloud NAT |
| `storage.tofu` | Log bucket: versioned, public access prevented, encrypted with its own rotating Cloud KMS key, with expiry rules |
{%- endif %}

## OpenTofu Features in Use

| Feature | Where | Since |
| --- | --- | --- |
| State and plan encryption with a cloud key service | `encryption.tofu` | 1.7 |
| Provider-defined functions (`provider::<name>::<function>`) | `storage.tofu`, `outputs.tofu` | 1.7 |
| Variables in the backend and encryption blocks | `backend.tofu`, `encryption.tofu` | 1.8 |
| `.tofu` files, which Terraform ignores | every file | 1.8 |
| The `enabled` meta-argument | `main.tofu`, `network.tofu` | 1.11 |
| Mocked providers and overrides in `tofu test` | `tests/` | 1.8 |

The stack needs OpenTofu 1.13 or later and does not run under Terraform.

## Working Locally

```bash
tofu fmt -recursive
tofu init -backend=false
tofu validate
tofu test
```

None of these needs credentials. To plan against real state, sign in to {% if values.cloud == 'aws' %}AWS{% elif values.cloud == 'azure' %}Azure{% else %}Google Cloud{% endif %}, set the state settings and pass the same variable file to every command; the backend and the encryption block are configured from it:

```bash
{% if values.cloud == 'aws' %}export TF_VAR_state_bucket=<state-bucket>
export TF_VAR_state_kms_key_id=<state-key-arn>{% elif values.cloud == 'azure' %}export ARM_SUBSCRIPTION_ID=<subscription-id>
export TF_VAR_state_storage_account=<storage-account>
export TF_VAR_state_key_vault_uri=https://<key-vault>.vault.azure.net{% else %}export TF_VAR_project_id=<project-id>
export TF_VAR_state_bucket=<state-bucket>
export TF_VAR_state_kms_key=<state-key-resource-name>{% endif %}

tofu init -var-file=environments/dev.tfvars
tofu plan -var-file=environments/dev.tfvars
```

Switching environment means `tofu init -reconfigure -var-file=environments/<environment>.tfvars`.

## Pipeline

| Trigger | What runs |
| --- | --- |
| Push to `main` | Format check, validation, tests, Trivy scan, then plan and apply of `dev` |
| Manual run | The same checks, then `plan`, `apply` or `destroy` of the chosen environment |

Plan and apply are skipped until the repository variables below exist. Applies run in the GitHub environment named after the target; add required reviewers to `staging` and `prod` under Settings → Environments.

### Repository Variables

The pipeline signs in with OIDC, so there is no secret to store. Add these under Settings → Secrets and variables → Actions → Variables:
{%- if values.cloud == 'aws' %}

| Variable | Value |
| --- | --- |
| `AWS_ROLE_ARN` | Role the pipeline assumes through the GitHub OIDC provider |
| `STATE_BUCKET` | S3 bucket that holds the state |
| `STATE_KMS_KEY_ARN` | ARN of the KMS key that encrypts state and plan files |
| `AWS_REGION` | Optional: region to sign in to; defaults to `${{ values.region }}` |

Create them once per AWS account:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="tofu-state-$ACCOUNT_ID"

aws s3api create-bucket --bucket "$STATE_BUCKET" --region ${{ values.region }} \
  --create-bucket-configuration LocationConstraint=${{ values.region }}
aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket "$STATE_BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws kms create-key --region ${{ values.region }} --description "OpenTofu state encryption" \
  --query KeyMetadata.Arn --output text
```

(`us-east-1` takes no `--create-bucket-configuration`.) Turn on rotation for the key with `aws kms enable-key-rotation`.

The role trusts `token.actions.githubusercontent.com` for this repository only:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
        "StringLike": { "token.actions.githubusercontent.com:sub": "repo:${{ values.destination.owner }}/${{ values.destination.repo }}:*" }
      }
    }
  ]
}
```

Grant it what the stack manages (VPC, S3, KMS and flow logs), `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` and `s3:ListBucket` on the state bucket, and `kms:GenerateDataKey` and `kms:Decrypt` on the state key. State locking uses a lock object in the same bucket, so no DynamoDB table is needed.
{%- elif values.cloud == 'azure' %}

| Variable | Value |
| --- | --- |
| `AZURE_CLIENT_ID` | Application (client) ID of the app registration or managed identity the pipeline signs in as |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription the stack is deployed to |
| `STATE_STORAGE_ACCOUNT` | Storage account that holds the state, in a `tfstate` container |
| `STATE_KEY_VAULT_URI` | URI of the Key Vault that holds the `tofu-state` key |

Create them once per subscription:

```bash
az group create --name rg-tofu-state --location ${{ values.region }}

az storage account create --name <storage-account> --resource-group rg-tofu-state \
  --sku Standard_GRS --min-tls-version TLS1_2 \
  --allow-blob-public-access false --allow-shared-key-access false
az storage container create --name tfstate --account-name <storage-account> --auth-mode login

az keyvault create --name <key-vault> --resource-group rg-tofu-state \
  --enable-rbac-authorization true --enable-purge-protection true
az keyvault key create --vault-name <key-vault> --name tofu-state --kty RSA --size 4096
```

Add a federated credential to the identity for each subject the pipeline runs as: `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:ref:refs/heads/main` for plans, and `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:environment:dev` (then `staging` and `prod`) for applies.

Grant the identity `Contributor` on the subscription or on the resource groups it manages, `Storage Blob Data Contributor` on the state container and `Key Vault Crypto User` on the key. The log storage account refuses shared keys, so whoever reads the logs needs a `Storage Blob Data` role as well.
{%- else %}

| Variable | Value |
| --- | --- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Resource name of the workload identity provider: `projects/<number>/locations/global/workloadIdentityPools/<pool>/providers/<provider>` |
| `GCP_SERVICE_ACCOUNT` | Email of the service account the pipeline impersonates |
| `GCP_PROJECT_ID` | Project the stack is deployed to |
| `STATE_BUCKET` | Cloud Storage bucket that holds the state |
| `STATE_KMS_KEY` | Resource name of the Cloud KMS key that encrypts state and plan files |

Create them once per project:

```bash
PROJECT_ID=<project-id>

gcloud storage buckets create "gs://$PROJECT_ID-tofu-state" --project "$PROJECT_ID" \
  --location ${{ values.region }} --uniform-bucket-level-access --public-access-prevention
gcloud storage buckets update "gs://$PROJECT_ID-tofu-state" --versioning

gcloud kms keyrings create tofu --project "$PROJECT_ID" --location ${{ values.region }}
gcloud kms keys create state --project "$PROJECT_ID" --location ${{ values.region }} \
  --keyring tofu --purpose encryption --rotation-period 90d \
  --next-rotation-time "$(date -u -d '+90 days' +%Y-%m-%dT%H:%M:%SZ)"
```

Restrict the workload identity provider to this repository with the attribute condition `assertion.repository == '${{ values.destination.owner }}/${{ values.destination.repo }}'` and let that principal impersonate the service account (`roles/iam.workloadIdentityUser`).

Grant the service account what the stack manages (`roles/compute.networkAdmin`, `roles/storage.admin`, `roles/cloudkms.admin`), `roles/storage.objectUser` on the state bucket and `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the state key. The APIs `compute.googleapis.com`, `cloudkms.googleapis.com` and `storage.googleapis.com` must be enabled in the project.
{%- endif %}

## State Encryption

OpenTofu asks the key service for a data key, encrypts state and plan files with AES-GCM and stores only ciphertext. Whoever can read the state bucket but cannot use the key learns nothing, and plan artifacts uploaded by the pipeline are protected the same way. `enforced = true` makes OpenTofu refuse unencrypted state.

To rotate to a new key, add a second `key_provider` and `method` to `encryption.tofu`, point `state` and `plan` at the new method and name the old one in a `fallback` block. Apply every environment once, then remove the old method.

## Adding an Environment

1. Copy a file in `environments/` and change its values.
2. Add the name to the validation of `environment` in `variables.tofu` and to the `environment` input of the workflow.
3. Create a GitHub environment with the same name.

## Owner

This stack is owned by **${{ values.owner }}**.
