# Kubernetes Platform Add-ons Template

This template creates a repository with the Terraform configuration that installs the platform add-ons of one Kubernetes cluster, and a pipeline that validates and deploys it. It is cloud-agnostic: it only needs a kubeconfig.

## What It Creates

- Traefik as ingress controller and default IngressClass, with HTTP redirected to HTTPS
- cert-manager with `letsencrypt-staging` and `letsencrypt-production` ClusterIssuers
- ExternalDNS for Cloudflare, DigitalOcean, AWS Route 53, Google Cloud DNS or Azure DNS
- Metrics Server
- A namespace per add-on with Pod Security Standards labels

Every add-on is a Helm release with a pinned chart version and can be switched off.

## Form Fields

| Field                        | Description                                                              |
| ---------------------------- | ------------------------------------------------------------------------ |
| Name                         | Name of the add-on set, usually the name of the cluster                  |
| Description                  | Purpose of the add-on set                                                |
| Owner                        | Team that owns the resource                                              |
| Environment                  | Environment of the cluster; production runs two replicas of every add-on |
| Ingress Controller (Traefik) | Install Traefik                                                          |
| cert-manager                 | Install cert-manager and the Let's Encrypt issuers                       |
| Certificate Contact E-mail   | Address Let's Encrypt sends expiry warnings to                           |
| ExternalDNS, DNS Provider    | Install ExternalDNS for the chosen provider                              |
| DNS Domain                   | Domain ExternalDNS is restricted to                                      |
| Metrics Server               | Install Metrics Server; off for clusters that ship it                    |
| Repository Location          | GitHub repository to create                                              |

Create one repository per cluster.

## The Generated Repository

| Path                                       | Content                                                 |
| ------------------------------------------ | ------------------------------------------------------- |
| `main.tf`, `variables.tf`, `outputs.tf`    | Terraform configuration (Helm and Kubernetes providers) |
| `charts/cluster-issuers/`                  | Local Helm chart with the ClusterIssuers                |
| `environments/<environment>.tfvars`        | Values of the cluster                                   |
| `tests/`                                   | Terraform tests that run against mocked providers       |
| `.github/workflows/terraform.yaml`         | Pipeline                                                |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml` | TechDocs and the catalog entity                         |

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests, lints the chart and scans everything with Trivy and Checkov. None of these needs a cluster.

Plan and apply are skipped until this repository secret exists:

| Secret           | Description                                                              |
| ---------------- | ------------------------------------------------------------------------ |
| `KUBECONFIG_B64` | Base64-encoded kubeconfig of the cluster, ideally with an expiring token |
| `DNS_API_TOKEN`  | Only for the Cloudflare and DigitalOcean DNS providers                   |

The Terraform state is kept in a Secret in the cluster itself, so no other storage is needed. The DNS token is passed as a write-only value and is not stored in the state. The documentation of the generated repository explains how to create the kubeconfig.

## Support

Contact the Platform Team for assistance.
