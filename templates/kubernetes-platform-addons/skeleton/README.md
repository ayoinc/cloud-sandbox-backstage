# ${{ values.name }}

${{ values.description }}

Terraform configuration that installs the platform add-ons of one Kubernetes cluster with Helm: an ingress controller (Traefik), cert-manager with Let's Encrypt issuers, ExternalDNS and Metrics Server. It works on any conformant cluster, managed or self-hosted.

## Quick Start

```bash
# Check the configuration without a cluster
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
helm lint charts/cluster-issuers --set email=you@your-domain
```

```bash
# Plan and apply from a workstation
export KUBE_CONFIG_PATH=~/.kube/config
export TF_VAR_dns_api_token=<dns api token>   # cloudflare and digitalocean only

terraform init \
  -backend-config="secret_suffix=${{ values.name }}" \
  -backend-config="namespace=kube-system"
terraform plan -var-file=environments/${{ values.envName }}.tfvars
terraform apply -var-file=environments/${{ values.envName }}.tfvars
```

Set `kube_context` in the variable file if the kubeconfig holds more than one cluster, so the add-ons can never land on the wrong one.

## Add-ons

| Add-on         | Namespace      | Chart version | Enabled                                           |
| -------------- | -------------- | ------------- | ------------------------------------------------- |
| Traefik        | `traefik`      | 42.3.1        | ${{ 'Yes' if values.ingressController else 'No' }} |
| cert-manager   | `cert-manager` | v1.21.3       | ${{ 'Yes' if values.certManager else 'No' }}       |
| ExternalDNS    | `external-dns` | 1.23.0        | ${{ 'Yes' if values.externalDns else 'No' }}       |
| Metrics Server | `kube-system`  | 3.14.0        | ${{ 'Yes' if values.metricsServer else 'No' }}     |

## Project Structure

```
.
├── main.tf                 # Namespaces and Helm releases
├── variables.tf            # Input variable declarations, including chart versions
├── outputs.tf              # Output values
├── providers.tf            # Kubernetes and Helm provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # State backend (a Secret in the cluster)
├── charts/
│   └── cluster-issuers/    # Local chart with the Let's Encrypt ClusterIssuers
├── environments/
│   └── ${{ values.envName }}.tfvars   # Values of this cluster
├── tests/
│   └── addons.tftest.hcl   # Terraform tests against mocked providers
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## CI/CD

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

- **Checks** (no cluster needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, `helm lint`, Trivy and Checkov
- **Plan and apply** once the repository secret `KUBECONFIG_B64` exists{% if values.externalDns and values.dnsProvider in ['cloudflare', 'digitalocean'] %}; ExternalDNS also needs `DNS_API_TOKEN`{% endif %}

Apply and destroy run in the GitHub environment `${{ values.envName }}`; add required reviewers to it to approve changes. Destroy and drift detection are run from **Actions > Terraform > Run workflow**. The [documentation](docs/index.md) explains how to create the kubeconfig.

## Documentation

See the [docs](docs/) directory, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
