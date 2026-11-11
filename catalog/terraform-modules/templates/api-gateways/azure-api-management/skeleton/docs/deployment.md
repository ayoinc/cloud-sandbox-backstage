# Deployment

Two workflows run on every push to `main` and on every pull request.

| Workflow | Jobs |
| --- | --- |
| CI (`.github/workflows/ci.yml`) | `Terraform`: format check, `init -backend=false`, `validate`, `terraform test`, tflint. `Security scan`: Trivy. `Documentation`: `mkdocs build --strict`. |
| Deploy (`.github/workflows/deploy.yml`) | `Deployment credentials`, `Plan`, `Apply`. |

CI needs no credentials. `terraform test` applies the configuration with the
committed variable values against mocked providers, so mistakes in
`terraform.tfvars` or `apis.auto.tfvars.json` fail the pull request.

In Deploy, the first job checks whether the settings below exist. Until they
do, `Plan` and `Apply` are skipped and the run succeeds.

## Settings in GitHub

Repository **secrets or variables** (either works):

| Name | Value |
| --- | --- |
| `AZURE_CLIENT_ID` | Client ID of the deployment identity |
| `AZURE_TENANT_ID` | Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription the instance is deployed to |

Repository **variables**:

| Name | Value |
| --- | --- |
| `TF_STATE_STORAGE_ACCOUNT` | Storage account that holds the Terraform state |
| `TF_STATE_CONTAINER` | Blob container; optional, default `tfstate` |

The state is stored in the blob `<repository name>/terraform.tfstate`.

`Apply` runs in the GitHub environment `production`. Add required reviewers to
that environment to approve each apply.

## Deployment identity

The workflows sign in with OpenID Connect; no client secret is stored.

1. Create an app registration or a user-assigned managed identity.
2. Add federated credentials for this repository with these subjects:

    | Used by | Subject |
    | --- | --- |
    | `Plan` on `main` | `repo:<owner>/<repository>:ref:refs/heads/main` |
    | `Plan` on pull requests | `repo:<owner>/<repository>:pull_request` |
    | `Apply` | `repo:<owner>/<repository>:environment:production` |

3. Grant the identity:

    | Scope | Role or permission | Needed for |
    | --- | --- | --- |
    | Subscription | Contributor | Resource group and resources. The role also registers resource providers. |
    | State container | Storage Blob Data Contributor | Reading and writing the state |
    | Microsoft Graph | Application permission `Application.ReadWrite.OwnedBy` with admin consent | The app registration for Microsoft Entra ID sign-in on the developer portal. Only with `enable_portal` and `enable_azure_ad` outside the Basic tier. |

The storage account and the container must exist before the first run.

## First deployment

1. Set `publisher_name` and `publisher_email` in `infra/terraform.tfvars`.
2. Configure the settings above.
3. Push to `main` or start the Deploy workflow by hand.

Creating the instance takes 30 to 60 minutes; the `Apply` job allows 180. The
name of the instance is globally unique: if `service_name` is taken, the apply
fails and the name has to be changed.

Pull requests show the plan in the log of the `Plan` job. No plan file is
stored as an artifact, because a plan file contains the secrets of the state.
`Apply` therefore plans again before it applies.

## Running Terraform locally

```bash
az login
export ARM_SUBSCRIPTION_ID=<subscription>
cd infra
terraform init \
  -backend-config="storage_account_name=<account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=<repository name>/terraform.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform plan
```
