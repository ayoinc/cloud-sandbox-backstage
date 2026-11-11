# ${{ values.name }}

${{ values.description }}

## What Is Managed

| Area             | Resources                                                                                           |
| ---------------- | --------------------------------------------------------------------------------------------------- |
| Zone             | `${{ values.domain }}`{% if values.existingZoneId %} (existing zone `${{ values.existingZoneId }}`){% else %}, created by this configuration{% endif %} |
| TLS              | `${{ values.sslMode }}` origin encryption, TLS ${{ values.minTlsVersion }} minimum, TLS 1.3, HTTPS redirect, HSTS, 0-RTT off |
| DNS              | Records in `dns_records`, DNSSEC and CAA records                                                    |
| WAF              | Custom rules{% if values.plan != 'free' %}, Cloudflare Managed Ruleset, OWASP Core Ruleset{% endif %}{% if values.rateLimiting %}, a rate limiting rule{% endif %} |
| Response headers | `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`                |

## Credentials

Nothing secret is stored in this repository. The pipeline reads these repository secrets:

| Secret                 | Description                                              |
| ---------------------- | -------------------------------------------------------- |
| `CLOUDFLARE_API_TOKEN` | API token restricted to this zone (permissions below)    |
| `CLOUDFLARE_ACCOUNT_ID`| ID of the account that owns the zone                     |
| `R2_ACCESS_KEY_ID`     | Access key of an R2 API token for the state bucket       |
| `R2_SECRET_ACCESS_KEY` | Secret key of that R2 API token                          |
| `TF_STATE_BUCKET`      | Name of the R2 bucket that holds the Terraform state     |

### API Token

Create the token under **My Profile > API Tokens > Create Custom Token** with the fewest permissions that work:

| Scope   | Permission                                     |
| ------- | ---------------------------------------------- |
| Zone    | Zone: Edit, Zone Settings: Edit, DNS: Edit     |
| Zone    | Zone WAF: Edit, Transform Rules: Edit          |
| Account | Account Rulesets: Read                         |

Restrict the zone resources to `${{ values.domain }}` once the zone exists. Creating the zone itself needs the token to cover all zones of the account for the first apply. Cloudflare does not issue short-lived credentials to GitHub Actions, so give the token an expiry date and rotate it.

### State Bucket

```bash
npx wrangler r2 bucket create <state bucket>
```

Then create an R2 API token under **R2 > Manage API Tokens** with *Object Read & Write* on that bucket only. Its access key ID and secret access key are the two `R2_*` secrets. The state is locked with a lock file in the bucket.

## After the First Apply

1. If the zone was created here, set the name servers from the `name_servers` output at the registrar.
2. Add the DS record from the `dnssec_ds_record` output at the registrar to complete DNSSEC.
3. Once every subdomain serves HTTPS, set `include_subdomains` (and, if wanted, `preload`) in `hsts`.

## Managing an Existing Zone

Rulesets are unique per phase. If the zone already has custom, rate limiting or transform rules, import them before the first apply so they are not rejected as duplicates:

```bash
terraform import 'cloudflare_ruleset.custom_firewall[0]' zones/<zone_id>/<ruleset_id>
```

## Pipeline

| Job             | Runs                                             | Needs credentials |
| --------------- | ------------------------------------------------ | ----------------- |
| Validate        | `terraform fmt -check`, `terraform validate`     | No                |
| TFLint          | Lint rules in `.tflint.hcl`                      | No                |
| Terraform Tests | `terraform test` against a mocked provider       | No                |
| Security Scan   | Trivy and Checkov                                | No                |
| Plan, Apply     | On push to `main` and on demand                  | Yes               |
| Destroy, Drift  | On demand from **Run workflow**                  | Yes               |

Drift detection opens an issue when the zone no longer matches the configuration.

## Provider Versions

`versions.tf` constrains the providers to a minor release line and `.terraform.lock.hcl` pins the exact releases, with checksums for Linux and macOS on x86-64 and Arm64. To upgrade:

```bash
terraform init -backend=false -upgrade
terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64
```
