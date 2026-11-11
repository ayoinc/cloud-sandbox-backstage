# Hetzner Cloud Server Template

This template creates a repository with the Terraform configuration of one or more Hetzner Cloud servers and a pipeline that validates and deploys it.

## What It Creates

- A private network with a subnet, and the servers attached to it with fixed addresses
- A firewall that is closed to the internet until SSH or web access is opened explicitly
- A spread placement group that keeps the servers on different hosts
- cloud-init hardening: an admin user with key sign-in, no root or password sign-in, automatic security updates and fail2ban
- An optional load balancer that reaches the servers over the private network
- Backups and deletion protection in production

## Form Fields

| Field                                  | Description                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------ |
| Name                                   | Name of the servers; the environment and a number are appended                       |
| Description                            | Purpose of the deployment                                                            |
| Owner                                  | Team that owns the resource                                                          |
| Environment                            | Environment the pipeline deploys on push; variable files for all three are generated |
| Location                               | Hetzner Cloud location                                                               |
| Server Type, Number of Servers         | Size of the chosen environment                                                       |
| Operating System                       | Ubuntu or Debian image                                                               |
| SSH Key Name                           | Name of a key already uploaded to the Hetzner Cloud project                          |
| SSH Source Range                       | Optional network allowed to reach SSH; empty keeps SSH closed                        |
| Allow HTTP and HTTPS From the Internet | Opens ports 80 and 443 on the servers                                                |
| Load Balancer                          | Puts a load balancer in front of the servers                                         |
| Repository Location                    | GitHub repository to create                                                          |

## The Generated Repository

| Path                                                       | Content                                            |
| ---------------------------------------------------------- | -------------------------------------------------- |
| `main.tf`, `cloud-init.yaml.tftpl`, `variables.tf`         | Terraform configuration                            |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                  |
| `tests/`                                                   | Terraform tests that run against a mocked provider |
| `.github/workflows/terraform.yaml`                         | Pipeline                                           |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml`                 | TechDocs and the catalog entity                    |

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov. None of these needs a cloud account.

Plan and apply are skipped until these repository secrets exist:

| Secret                                     | Description                                          |
| ------------------------------------------ | ---------------------------------------------------- |
| `HCLOUD_TOKEN`                             | API token of the Hetzner Cloud project               |
| `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | Object Storage key for the Terraform state           |
| `TF_STATE_BUCKET`                          | Object Storage bucket that holds the Terraform state |

Credentials are never written to the repository. The documentation of the generated repository explains how to create them.

## Support

Contact the Platform Team for assistance.
