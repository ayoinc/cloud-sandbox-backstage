{%- set windows = values.base_os == "windows-2022" -%}
# ${{ values.name }}

${{ values.description }}

## Configuration

| Setting  | Value                         |
| -------- | ----------------------------- |
| Provider | `${{ values.cloud_provider }}` |
| Base OS  | `${{ values.base_os }}`       |
{%- if values.cloud_provider == "vmware" %}
| Datacenter | `${{ values.region }}`      |
| VM size  | `${{ values.instance_type }}` (CPUs x memory in MB) |
{%- else %}
| Region   | `${{ values.region }}`        |
| Size     | `${{ values.instance_type }}` |
{%- endif %}

The values are defaults of variables in `image.pkr.hcl`; override them with
`-var name=value`.

## Build locally

```bash
packer init .
packer validate .
packer build .
```

{% if values.cloud_provider == "aws" -%}
Packer uses the AWS credentials of your shell (`aws configure`, `aws sso login`
or `AWS_*` environment variables).
{%- elif values.cloud_provider == "azure" -%}
Sign in with `az login` and set `ARM_SUBSCRIPTION_ID`. The resource group named
by the `resource_group` variable must exist.
{%- elif values.cloud_provider == "gcp" -%}
Sign in with `gcloud auth application-default login` and set
`GOOGLE_CLOUD_PROJECT`.
{%- elif values.cloud_provider == "vmware" -%}
Set `VSPHERE_SERVER`, `VSPHERE_USER`, `VSPHERE_PASSWORD`, `VSPHERE_CLUSTER`,
`VSPHERE_DATASTORE`, `PACKER_GUEST_USERNAME` and `PACKER_GUEST_PASSWORD`. A VM
template named `${{ values.base_os }}` (variable `source_template`) is cloned,
provisioned and converted to a new template.
{%- endif %}

## Provisioning

{% if windows -%}
`scripts/provision.ps1` installs the software baked into the image.
{%- else -%}
`scripts/provision.sh` installs the software baked into the image.
{%- endif %}

## Pipeline

`.github/workflows/packer.yaml` runs on every push and pull request:

| Job                       | What it does                                                    |
| ------------------------- | --------------------------------------------------------------- |
| Validate                  | `packer fmt -check`, `packer init`, `packer validate`           |
{%- if windows %}
| Lint provisioning scripts | PSScriptAnalyzer on `scripts/provision.ps1`                     |
{%- else %}
| Lint provisioning scripts | `bash -n` and ShellCheck on `scripts/`                          |
{%- endif %}
| Secret scan               | Trivy looks for committed credentials                           |
| Build image               | `packer build`, only on `main` and only once credentials exist  |

The build is skipped until these repository secrets are set:

{% if values.cloud_provider == "aws" -%}
- `AWS_ROLE_ARN`: IAM role the workflow assumes through GitHub OIDC.
{%- elif values.cloud_provider == "azure" -%}
- `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`: app
  registration with a federated credential for this repository.
{%- elif values.cloud_provider == "gcp" -%}
- `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT`, `GCP_PROJECT_ID`:
  workload identity federation for this repository.
{%- elif values.cloud_provider == "vmware" -%}
- `VSPHERE_SERVER`, `VSPHERE_USER`, `VSPHERE_PASSWORD`: vCenter access.
- `PACKER_GUEST_USERNAME`, `PACKER_GUEST_PASSWORD`: account in the source
  template.

Repository variables `VSPHERE_CLUSTER` and `VSPHERE_DATASTORE` choose where the
build VM runs, and `PACKER_RUNNER` names a self-hosted runner that can reach
vCenter.
{%- endif %}
