# ${{ values.name }}

${{ values.description }}

## Architecture

| Resource                              | Purpose                                                                    |
| ------------------------------------- | -------------------------------------------------------------------------- |
| `digitalocean_vpc`                    | Private network, one address range per environment                         |
| `digitalocean_droplet`                | `${{ values.image }}` Droplets named `${{ values.name }}-<environment>-<number>` in `${{ values.region }}` |
| `digitalocean_firewall`               | Cloud firewall attached to the Droplets                                    |
| `digitalocean_reserved_ip`            | One reserved IPv4 address per Droplet, when `reserved_ip` is on            |
| `digitalocean_project`                | Groups the Droplets in the control panel and on the invoice                |

Monitoring, the Droplet agent and IPv6 are enabled on every Droplet.

## Security Defaults

| Area       | Default                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------- |
| Firewall   | Denies all inbound traffic except from the private network; SSH and web are opened explicitly |
| SSH        | Key sign-in for the user `ops` only; root and password sign-in are disabled                 |
| Updates    | Security updates are installed daily by `unattended-upgrades`                               |
| Brute force| `fail2ban` bans addresses after repeated failed sign-ins                                    |
| Secrets    | None in the repository; the public SSH key is read from the account by name                 |

`ssh_allowed_cidrs` refuses `0.0.0.0/0`: name the networks that administer the servers. With an empty list SSH is unreachable from the internet, and the Droplet console in the control panel is the way in.

## First-Boot Configuration

`cloud-init.yaml.tftpl` is rendered by Terraform and runs once, on the first boot. Add packages, files and commands there to install your service. Because user data is only read on the first boot, changing the file **replaces** the servers on the next apply; roll the change out through `dev` first.

## Credentials

The pipeline reads these repository secrets:

| Secret                     | Description                                              |
| -------------------------- | -------------------------------------------------------- |
| `DIGITALOCEAN_TOKEN`       | API token with the scopes below                          |
| `SPACES_ACCESS_KEY_ID`     | Spaces access key for the state bucket                   |
| `SPACES_SECRET_ACCESS_KEY` | Secret of that access key                                |
| `TF_STATE_BUCKET`          | Name of the Spaces bucket that holds the Terraform state |

Token scopes: `droplet`, `firewall`, `vpc`, `reserved_ip`, `project` (all), `tag` (create, read) and `ssh_key` (read).

### API Token

Create a custom-scoped token under **API > Tokens** with the scopes listed above and an expiry date. DigitalOcean does not issue short-lived credentials to GitHub Actions, so rotate the token before it expires.

### State Bucket

Create a private Spaces bucket in the region of this project and a Spaces access key limited to that bucket (**Spaces Object Storage > Access Keys > Limited Access**). The key pair is the two `SPACES_*` secrets. If the bucket is in another region than `${{ values.region }}`, set the repository variable `TF_STATE_REGION` to it.

The pipeline runs one Terraform job per branch at a time, which keeps two runs from writing the state together; do not apply from a workstation while the pipeline runs.

## SSH Keys

`ssh_key_names` lists keys by the name they have under **Settings > Security** of the DigitalOcean account (this project: `${{ values.sshKeyName }}`). Their public keys are installed for the user `ops`. Adding or removing a key replaces the Droplets, since keys are installed on the first boot.

## Pipeline

| Job             | Runs                                         | Needs credentials |
| --------------- | -------------------------------------------- | ----------------- |
| Validate        | `terraform fmt -check`, `terraform validate` | No                |
| TFLint          | Lint rules in `.tflint.hcl`                  | No                |
| Terraform Tests | `terraform test` against a mocked provider   | No                |
| Security Scan   | Trivy and Checkov                            | No                |
| Plan, Apply     | On push to `main` and on demand              | Yes               |
| Destroy, Drift  | On demand from **Run workflow**              | Yes               |

A push to `main` plans and applies the `${{ values.envName }}` environment. Drift detection opens an issue when the infrastructure no longer matches the configuration.

## Provider Versions

`versions.tf` constrains the providers to a minor release line and `.terraform.lock.hcl` pins the exact releases, with checksums for Linux and macOS on x86-64 and Arm64. To upgrade:

```bash
terraform init -backend=false -upgrade
terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64
```
