{%- set windows = values.base_os == "windows-2022" -%}
{%- set provider = values.cloud_provider -%}
# ${{ values.name }}

${{ values.description }}

## Overview

This repository builds an immutable machine image with
[Packer](https://developer.hashicorp.com/packer). Every build starts from a
clean `${{ values.base_os }}` base image, installs the software listed in the
provisioning script and registers the result as a new image, so that machines
are replaced rather than patched in place.

```d2
direction: right

base: Base image {
  label: "${{ values.base_os }}"
  shape: package
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

packer: Packer {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  init: packer init
  validate: packer validate
  build: packer build

  init -> validate -> build
}

provision: Provisioning {
  label: "scripts/provision.{% if windows %}ps1{% else %}sh{% endif %}"
  shape: document
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

image: New image {
  label: "${{ values.name }}-<timestamp>"
  shape: hexagon
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

base -> packer.build: temporary build machine
packer.build -> provision: runs
provision -> image: captured as
```

---

## Configuration Summary

| Setting        | Value                          |
| -------------- | ------------------------------ |
| Image name     | `${{ values.name }}`           |
| Provider       | `${{ values.cloud_provider }}` |
| Base OS        | `${{ values.base_os }}`        |
{%- if provider == "vmware" %}
| Datacenter     | `${{ values.region }}`         |
| VM size        | `${{ values.instance_type }}` (CPUs x memory in MB) |
{%- else %}
| Region         | `${{ values.region }}`         |
| Build size     | `${{ values.instance_type }}`  |
{%- endif %}
| Docker         | ${{ "installed" if values.install_docker else "not installed" }} |
{%- if windows %}
| Ansible access | ${{ "OpenSSH Server installed" if values.install_ansible else "not configured" }} |
{%- else %}
| Ansible        | ${{ "installed" if values.install_ansible else "not installed" }} |
{%- endif %}
| Owner          | `${{ values.owner }}`          |

---

## Repository Structure

```
${{ values.name }}/
├── .github/workflows/packer.yaml   # Validation and build pipeline
├── docs/index.md                   # This documentation
├── scripts/
{%- if windows %}
{%- if provider == "aws" %}
│   ├── enable-winrm.ps1            # EC2 user data that lets Packer connect
{%- endif %}
│   └── provision.ps1               # Software installed into the image
{%- else %}
│   └── provision.sh                # Software installed into the image
{%- endif %}
├── image.pkr.hcl                   # Packer template: plugin, variables, source, build
├── catalog-info.yaml               # Backstage catalog entry
├── mkdocs.yml                      # TechDocs configuration
└── README.md
```

---

## CI/CD Pipeline

`.github/workflows/packer.yaml` runs on every push to `main`, on pull requests
and on demand.

| Job                       | What it does                                                   | Needs credentials |
| ------------------------- | -------------------------------------------------------------- | ----------------- |
| Validate                  | `packer fmt -check`, `packer init`, `packer validate`          | No                |
{%- if windows %}
| Lint provisioning scripts | PSScriptAnalyzer on `scripts/provision.ps1`                    | No                |
{%- else %}
| Lint provisioning scripts | `bash -n` and ShellCheck on `scripts/`                         | No                |
{%- endif %}
| Secret scan               | Trivy looks for committed credentials                          | No                |
| Build image               | `packer build` on `main` and on manual runs                    | Yes               |

The build job is skipped, not failed, while its credentials are missing. Add
these repository secrets to turn it on:

{% if provider == "aws" -%}
| Secret         | Purpose                                                    |
| -------------- | ---------------------------------------------------------- |
| `AWS_ROLE_ARN` | IAM role the workflow assumes through GitHub OIDC          |

The role needs the
[permissions Packer documents for the Amazon EBS builder](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon#iam-task-or-instance-role)
and a trust policy for `token.actions.githubusercontent.com` restricted to this
repository.
{%- elif provider == "azure" -%}
| Secret                  | Purpose                                             |
| ----------------------- | --------------------------------------------------- |
| `AZURE_CLIENT_ID`       | App registration with a federated credential for this repository |
| `AZURE_TENANT_ID`       | Tenant of that app registration                     |
| `AZURE_SUBSCRIPTION_ID` | Subscription the image is built in                  |

The identity needs the Contributor role on the subscription, and the resource
group named by the `resource_group` variable (default `${{ values.name }}-images`)
must exist.
{%- elif provider == "gcp" -%}
| Secret                           | Purpose                                    |
| -------------------------------- | ------------------------------------------ |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider for this repository |
| `GCP_SERVICE_ACCOUNT`            | Service account the workflow impersonates  |
| `GCP_PROJECT_ID`                 | Project the image is built in              |

The service account needs `roles/compute.instanceAdmin.v1` and
`roles/iam.serviceAccountUser` in the project.
{%- elif provider == "vmware" -%}
| Secret                  | Purpose                                             |
| ----------------------- | --------------------------------------------------- |
| `VSPHERE_SERVER`        | vCenter Server hostname                             |
| `VSPHERE_USER`          | vCenter user                                        |
| `VSPHERE_PASSWORD`      | Password of that user                               |
| `PACKER_GUEST_USERNAME` | Account in the source template Packer connects with |
| `PACKER_GUEST_PASSWORD` | Password of that account                            |

| Variable            | Purpose                                                  |
| ------------------- | -------------------------------------------------------- |
| `VSPHERE_CLUSTER`   | Cluster that runs the build VM                           |
| `VSPHERE_DATASTORE` | Datastore of the build VM                                |
| `PACKER_RUNNER`     | Label of a self-hosted runner that can reach vCenter     |
{%- endif %}

---

## Building Locally

Install Packer 1.9 or later, then:

```bash
packer init .
packer fmt -check .
packer validate .
packer build .
```

{% if provider == "aws" -%}
Packer uses the AWS credentials of your shell: `aws sso login`, a profile in
`AWS_PROFILE`, or `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
{%- elif provider == "azure" -%}
Sign in with `az login` and export `ARM_SUBSCRIPTION_ID`.
{%- elif provider == "gcp" -%}
Sign in with `gcloud auth application-default login` and export
`GOOGLE_CLOUD_PROJECT`.
{%- elif provider == "vmware" -%}
Export `VSPHERE_SERVER`, `VSPHERE_USER`, `VSPHERE_PASSWORD`, `VSPHERE_CLUSTER`,
`VSPHERE_DATASTORE`, `PACKER_GUEST_USERNAME` and `PACKER_GUEST_PASSWORD`.
vCenter must hold a VM template named `${{ values.base_os }}`; another name can
be given with `-var source_template=<name>`.
{%- endif %}

### Variables

Every setting chosen when this repository was created is the default of a
variable in `image.pkr.hcl`. Override one for a single build with `-var`:

```bash
packer build -var image_name=${{ values.name }}-test .
```

Each image is named `<image_name>-<UTC timestamp>`, and the build writes the
identifier of the new image to `manifest.json`.

---

## Changing What Is Installed

{% if windows -%}
Edit `scripts/provision.ps1`. It runs as an administrator on the temporary
build machine, and the machine restarts once after it. Additional packages are
installed with Chocolatey.
{%- else -%}
Edit `scripts/provision.sh`. It runs as root on the temporary build machine and
stops at the first failing command.
{%- endif %}

Keep secrets out of the script and out of the image: anything written to disk
during a build is readable by everyone who can launch the image.

---

## Troubleshooting

| Symptom                                   | Cause and fix                                                         |
| ----------------------------------------- | --------------------------------------------------------------------- |
| `packer init` is rate limited             | Set `PACKER_GITHUB_API_TOKEN` to a GitHub token                       |
| `packer fmt -check` fails in the pipeline | Run `packer fmt .` and commit the result                              |
{%- if windows %}
| Build waits for WinRM until it times out  | The build machine must accept inbound TCP 5986 from where Packer runs |
{%- else %}
| Build waits for SSH until it times out    | The build machine must accept inbound TCP 22 from where Packer runs   |
{%- endif %}
| Build job is skipped                      | The secrets listed under CI/CD Pipeline are not set                   |

Run a build with `PACKER_LOG=1` for a detailed log, and with `-on-error=ask` to
keep the build machine for inspection when a provisioner fails.

---

## References

- [Packer documentation](https://developer.hashicorp.com/packer/docs)
- [Packer integrations](https://developer.hashicorp.com/packer/integrations)
- [setup-packer GitHub Action](https://github.com/hashicorp/setup-packer)
