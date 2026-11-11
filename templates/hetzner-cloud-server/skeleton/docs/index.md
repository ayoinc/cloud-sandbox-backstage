# ${{ values.name }}

${{ values.description }}

## Architecture

| Resource                  | Purpose                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `hcloud_network`          | Private network and subnet, one address range per environment                      |
| `hcloud_server`           | `${{ values.image }}` servers of type `${{ values.serverType }}` in `${{ values.location }}`, named `${{ values.name }}-<environment>-<number>` |
| `hcloud_placement_group`  | Spreads the servers over different physical hosts                                  |
| `hcloud_firewall`         | Firewall attached to the servers                                                   |
| `hcloud_load_balancer`    | Optional; forwards TCP 80 and 443 to the servers over the private network          |

The servers get fixed private addresses from `.10` upwards. Resource names include the environment, so the three environments can share one Hetzner Cloud project.

## Security Defaults

| Area       | Default                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------- |
| Firewall   | Denies all inbound traffic except from the private network; SSH and web are opened explicitly |
| SSH        | Key sign-in for the user `ops` only; root and password sign-in are disabled                 |
| Updates    | Security updates are installed daily by `unattended-upgrades`                               |
| Brute force| `fail2ban` bans addresses after repeated failed sign-ins                                    |
| Secrets    | None in the repository; the public SSH key is read from the account by name                 |

`ssh_allowed_cidrs` refuses `0.0.0.0/0`: name the networks that administer the servers. With an empty list SSH is unreachable from the internet, and the console in the Hetzner Cloud Console is the way in.

## First-Boot Configuration

`cloud-init.yaml.tftpl` is rendered by Terraform and runs once, on the first boot. Add packages, files and commands there to install your service. Because user data is only read on the first boot, changing the file **replaces** the servers on the next apply; roll the change out through `dev` first.

## Load Balancer

With `load_balancer = true` the load balancer is the public entrance. It selects its targets by label, so servers added later join automatically, and it reaches them on their private addresses. TLS is passed through: the servers terminate HTTPS and hold the certificates. A target is healthy once something on the server accepts connections on the port. The firewall rule for direct web traffic (`allow_web`) is left out when the load balancer is on.

## Credentials

The pipeline reads these repository secrets:

| Secret                 | Description                                                         |
| ---------------------- | ------------------------------------------------------------------- |
| `HCLOUD_TOKEN`         | Read & Write API token of the Hetzner Cloud project                 |
| `S3_ACCESS_KEY_ID`     | Object Storage access key for the state bucket                      |
| `S3_SECRET_ACCESS_KEY` | Secret of that access key                                           |
| `TF_STATE_BUCKET`      | Name of the Object Storage bucket that holds the Terraform state    |

### API Token

Create the token under **Security > API Tokens** of the project. Hetzner Cloud tokens are scoped to one project and do not expire, and Hetzner does not issue short-lived credentials to GitHub Actions: store the token only as a repository secret and replace it regularly.

### State Bucket

Create a private bucket under **Object Storage** and S3 credentials under **Security > S3 Credentials**. The pipeline expects the bucket in `fsn1`; set the repository variable `TF_STATE_REGION` to `nbg1` or `hel1` if it is elsewhere.

The pipeline runs one Terraform job per branch at a time, which keeps two runs from writing the state together; do not apply from a workstation while the pipeline runs.

## SSH Keys

`ssh_key_names` lists keys by the name they have under **Security > SSH Keys** of the project (this deployment: `${{ values.sshKeyName }}`). Their public keys are installed for the user `ops`. Adding or removing a key replaces the servers, since keys are installed on the first boot.

## Server Types and Locations

Not every type is offered everywhere: the CX and CAX (Arm64) types exist in the European locations only. `hcloud server-type list` and `hcloud location list` show what is on offer. Changing `server_type` resizes the servers in place with a short downtime.

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
