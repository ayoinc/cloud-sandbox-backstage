# ${{ values.name }}

${{ values.description }}

## Architecture

| Resource                          | Purpose                                                                           |
| --------------------------------- | --------------------------------------------------------------------------------- |
| `oci_core_vcn`                    | Virtual cloud network, one address range per environment                          |
| `oci_core_default_security_list`  | The default security list, emptied so that it allows nothing                      |
| `oci_core_subnet`                 | {% if values.assignPublicIp %}Public subnet with a route to the internet gateway{% else %}Private subnet: public IP addresses are prohibited{% endif %} |
| Gateways                          | {% if values.assignPublicIp %}Internet gateway{% else %}NAT gateway for outbound traffic and service gateway for Oracle services{% endif %} |
| `oci_core_network_security_group` | The only thing that allows traffic to the instance                                |
| `oci_core_instance`               | `${{ values.shape }}` instance in `${{ values.region }}` from the newest ${{ 'Oracle Linux 9' if values.operatingSystem == 'oracle-linux-9' else 'Ubuntu 24.04' }} platform image |

## Security Defaults

| Area              | Default                                                                                  |
| ----------------- | ---------------------------------------------------------------------------------------- |
| Network           | No inbound rule except ICMP "fragmentation needed"; SSH and web are opened explicitly    |
| Exposure          | Private subnet without a public IP address unless `assign_public_ip` is set              |
| SSH               | Key sign-in for the default user only; `ssh_allowed_cidrs` refuses `0.0.0.0/0`           |
| Instance metadata | Legacy (v1) endpoints disabled                                                           |
| Encryption        | Boot volume encrypted at rest (always) and in transit                                    |
| Updates           | Security updates installed automatically (`dnf-automatic` or `unattended-upgrades`)      |
| Secrets           | None in the repository; the API signing key exists only as a repository secret           |

## Always Free

`VM.Standard.A1.Flex` (up to 4 OCPUs and 24 GB in total) and `VM.Standard.E2.1.Micro` are Always Free eligible in the home region of a tenancy, with 200 GB of block storage in total. An Always Free tenancy cannot create a NAT gateway: set `assign_public_ip = true` and list your networks in `ssh_allowed_cidrs`. Capacity for the A1 shape is limited; if the apply reports "Out of host capacity", try another `availability_domain_index` or run it again later.

## Signing In

{% if values.assignPublicIp -%}
```bash
ssh ${{ 'opc' if values.operatingSystem == 'oracle-linux-9' else 'ubuntu' }}@$(terraform output -raw public_ip)
```

SSH is reachable only from the networks in `ssh_allowed_cidrs`.
{%- else -%}
The instance has no public address. Create a session with the OCI Bastion service, which the Bastion plugin of the instance supports:

1. Create a bastion in the subnet from the `subnet_id` output (**Identity & Security > Bastion**) and allow your address.
2. Add the private address of the bastion endpoint to `ssh_allowed_cidrs` as a `/32`, and apply.
3. Create a managed SSH session for the user `${{ 'opc' if values.operatingSystem == 'oracle-linux-9' else 'ubuntu' }}` and use the command the console shows.
{%- endif %}

The Ubuntu platform images also run a host firewall that only admits SSH; open further ports there as well as in the network security group.

## Credentials

The pipeline reads these repository secrets:

| Secret                 | Description                                                    |
| ---------------------- | -------------------------------------------------------------- |
| `OCI_TENANCY_OCID`     | OCID of the tenancy                                            |
| `OCI_USER_OCID`        | OCID of the user that owns the API signing key                 |
| `OCI_FINGERPRINT`      | Fingerprint of the API signing key                             |
| `OCI_PRIVATE_KEY`      | Private key in PEM format                                      |
| `OCI_COMPARTMENT_OCID` | Compartment the resources are created in                       |
| `TF_STATE_BUCKET`      | Object Storage bucket that holds the Terraform state           |
| `TF_STATE_NAMESPACE`   | Object Storage namespace of the tenancy                        |

### Deployment User

Create a user for the pipeline, put it in a group and give that group only what this configuration needs, in the one compartment:

```
Allow group <group> to manage instance-family in compartment <compartment>
Allow group <group> to manage virtual-network-family in compartment <compartment>
Allow group <group> to use volume-family in compartment <compartment>
Allow group <group> to manage objects in compartment <compartment> where target.bucket.name = '<state bucket>'
Allow group <group> to read buckets in compartment <compartment>
```

Add an API signing key to the user (**User settings > API keys**); the console shows the fingerprint. The pipeline writes the key to the runner for the duration of a job and nowhere else. Rotate the key regularly: a user can hold three keys, so add the new one before removing the old.

### State Bucket

```bash
oci os bucket create --compartment-id <compartment ocid> --name <state bucket> --versioning Enabled
oci os ns get   # prints the namespace
```

The bucket is private by default. Versioning lets a damaged state be restored.

## First-Boot Configuration

`cloud-init.yaml` runs once, on the first boot. Add packages and commands there to install your service. Changing the file replaces the instance on the next apply.

## New Platform Images

The newest image is looked up when the instance is created; later images do not replace it. To rebuild on the current image:

```bash
terraform apply -var-file=environments/<environment>.tfvars -replace=oci_core_instance.this
```

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
