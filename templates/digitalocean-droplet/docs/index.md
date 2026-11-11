# DigitalOcean Droplet Template

This template creates a repository with the Terraform configuration of one or more DigitalOcean Droplets and a pipeline that validates and deploys it.

## What It Creates

- A VPC and the Droplets inside it, with monitoring and IPv6
- A cloud firewall that is closed to the internet until SSH or web access is opened explicitly
- cloud-init hardening: an admin user with key sign-in, no root or password sign-in, automatic security updates and fail2ban
- Optional reserved IPv4 addresses and weekly backups in production
- A DigitalOcean project that groups the resources

## Form Fields

| Field                                  | Description                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------ |
| Name                                   | Name of the Droplets; the environment and a number are appended                      |
| Description                            | Purpose of the deployment                                                            |
| Owner                                  | Team that owns the resource                                                          |
| Environment                            | Environment the pipeline deploys on push; variable files for all three are generated |
| Region                                 | DigitalOcean region                                                                  |
| Droplet Size, Number of Droplets       | Size of the chosen environment                                                       |
| Operating System                       | Ubuntu or Debian image                                                               |
| SSH Key Name                           | Name of a key already uploaded to the DigitalOcean account                           |
| SSH Source Range                       | Optional network allowed to reach SSH; empty keeps SSH closed                        |
| Allow HTTP and HTTPS From the Internet | Opens ports 80 and 443                                                               |
| Reserved IP                            | A reserved IPv4 address per Droplet                                                  |
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

| Secret                                             | Description                                  |
| -------------------------------------------------- | -------------------------------------------- |
| `DIGITALOCEAN_TOKEN`                               | Scoped API token                             |
| `SPACES_ACCESS_KEY_ID`, `SPACES_SECRET_ACCESS_KEY` | Spaces key for the Terraform state           |
| `TF_STATE_BUCKET`                                  | Spaces bucket that holds the Terraform state |

Credentials are never written to the repository. The documentation of the generated repository explains how to create them.

## Support

Contact the Platform Team for assistance.
