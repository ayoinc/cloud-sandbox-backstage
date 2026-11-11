# Cloudflare Zone Template

This template creates a repository with the Terraform configuration of a Cloudflare zone and a pipeline that validates and deploys it.

## What It Creates

- The zone itself, or the management of a zone that already exists
- TLS hardening: strict origin encryption, a minimum TLS version, TLS 1.3, HTTPS redirect and HSTS
- DNSSEC, CAA records and the DNS records of the zone
- WAF rulesets: custom rules, a rate limiting rule and, on paid plans, the Cloudflare Managed and OWASP Core rulesets
- Security response headers through a transform rule

## Form Fields

| Field                    | Description                                                     |
| ------------------------ | --------------------------------------------------------------- |
| Name                     | Name of the repository and of the catalog entry                 |
| Description              | Purpose of the zone                                             |
| Owner                    | Team that owns the resource                                     |
| Domain                   | Apex domain of the zone                                         |
| Existing Zone ID         | Empty to create the zone; the ID of a zone to manage it instead |
| Cloudflare Plan          | Decides whether the managed WAF rulesets are deployed           |
| SSL/TLS Encryption Mode  | `strict` or `full`                                              |
| Minimum TLS Version      | 1.2 or 1.3                                                      |
| Origin IPv4 Address      | Optional; creates proxied apex and `www` records                |
| Rate Limit Sign-in Paths | Adds a rate limiting rule that fits the Free plan               |
| Repository Location      | GitHub repository to create                                     |

## The Generated Repository

| Path                                       | Content                                            |
| ------------------------------------------ | -------------------------------------------------- |
| `main.tf`, `rulesets.tf`, `variables.tf`   | Terraform configuration (Cloudflare provider v5)   |
| `environments/prod.tfvars`                 | Values of the zone                                 |
| `tests/`                                   | Terraform tests that run against a mocked provider |
| `.github/workflows/terraform.yaml`         | Pipeline                                           |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml` | TechDocs and the catalog entity                    |

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov.

Plan and apply are skipped until these repository secrets exist:

| Secret                                     | Description                              |
| ------------------------------------------ | ---------------------------------------- |
| `CLOUDFLARE_API_TOKEN`                     | API token restricted to the zone         |
| `CLOUDFLARE_ACCOUNT_ID`                    | Account that owns the zone               |
| `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` | R2 credentials for the Terraform state   |
| `TF_STATE_BUCKET`                          | R2 bucket that holds the Terraform state |

Credentials are never written to the repository. The documentation of the generated repository lists the token permissions and explains how to create the state bucket.

### After the First Apply

Set the name servers and the DS record from the Terraform outputs at the registrar.

## Support

Contact the Platform Team for assistance.
