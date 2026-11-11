# Oracle Cloud Compute Instance Template

This template creates a repository with the Terraform configuration of an Oracle Cloud Infrastructure (OCI) compute instance and a pipeline that validates and deploys it.

## What It Creates

- A VCN whose default security list is emptied, with a subnet, route table and the gateways the instance needs
- A network security group that is closed until SSH or web access is opened explicitly
- A compute instance on the newest Oracle Linux or Ubuntu platform image, on a flexible or fixed shape, including the Always Free Ampere shape `VM.Standard.A1.Flex`
- Hardening: no legacy metadata endpoints, in-transit encryption of the boot volume, automatic security updates
- A private instance behind a NAT gateway by default, or a public one on request

## Form Fields

| Field               | Description                                                                          |
| ------------------- | ------------------------------------------------------------------------------------ |
| Instance Name       | Name of the instance; the environment is appended                                    |
| Description         | Purpose of the instance                                                              |
| Owner               | Team that owns the resource                                                          |
| Environment         | Environment the pipeline deploys on push; variable files for all three are generated |
| Region              | OCI region; Always Free resources need the home region of the tenancy                |
| Shape               | Compute shape, two of them Always Free eligible                                      |
| OCPUs, Memory       | Size of a flexible shape in the chosen environment                                   |
| Operating System    | Oracle Linux 9 or Ubuntu 24.04                                                       |
| Public IP Address   | Off for a private instance; Always Free tenancies need it on                         |
| SSH Public Key      | Public key installed for the default user                                            |
| SSH Source Range    | Optional network allowed to reach SSH; empty keeps SSH closed                        |
| Repository Location | GitHub repository to create                                                          |

## The Generated Repository

| Path                                                       | Content                                            |
| ---------------------------------------------------------- | -------------------------------------------------- |
| `main.tf`, `network.tf`, `cloud-init.yaml`, `variables.tf` | Terraform configuration                            |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                  |
| `tests/`                                                   | Terraform tests that run against a mocked provider |
| `.github/workflows/terraform.yaml`                         | Pipeline                                           |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml`                 | TechDocs and the catalog entity                    |

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov. None of these needs a cloud account.

Plan and apply are skipped until these repository secrets exist:

| Secret                                                                    | Description                                   |
| ------------------------------------------------------------------------- | --------------------------------------------- |
| `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT`, `OCI_PRIVATE_KEY` | API signing key of the deployment user        |
| `OCI_COMPARTMENT_OCID`                                                    | Compartment to deploy into                    |
| `TF_STATE_BUCKET`, `TF_STATE_NAMESPACE`                                   | Object Storage bucket for the Terraform state |

Credentials are never written to the repository. The API signing key is written to the runner only while a job runs. The documentation of the generated repository explains how to create them.

## Support

Contact the Platform Team for assistance.
