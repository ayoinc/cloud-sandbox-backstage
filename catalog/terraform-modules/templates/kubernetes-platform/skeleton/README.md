# Multi-Cloud Kubernetes Platform

Production-ready Kubernetes platform with GitOps, observability, and security on AWS EKS, Azure AKS, or GCP GKE.

## Architecture

```
                              ┌─────────────────────────────────────────────────────────────┐
                              │                    Kubernetes Platform                       │
                              │                                                              │
                              │  ┌───────────────────────────────────────────────────────┐  │
                              │  │                    Cloud Provider                      │  │
                              │  │              (AWS EKS / Azure AKS / GCP GKE)           │  │
                              │  │                                                        │  │
┌──────────┐                  │  │  ┌─────────────────────────────────────────────────┐  │  │
│          │    HTTPS         │  │  │              Ingress Controller                  │  │  │
│  Users   │─────────────────▶│  │  │           (NGINX / Traefik / Istio)              │  │  │
│          │                  │  │  └────────────────────┬────────────────────────────┘  │  │
└──────────┘                  │  │                       │                               │  │
                              │  │  ┌────────────────────▼────────────────────────────┐  │  │
                              │  │  │              Application Workloads               │  │  │
                              │  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐          │  │  │
                              │  │  │  │   App   │  │   App   │  │   App   │          │  │  │
                              │  │  │  │  Pod 1  │  │  Pod 2  │  │  Pod 3  │          │  │  │
                              │  │  │  └─────────┘  └─────────┘  └─────────┘          │  │  │
                              │  │  └──────────────────────────────────────────────────┘  │  │
                              │  │                                                        │  │
                              │  │  ┌──────────────────┐  ┌──────────────────┐           │  │
                              │  │  │     ArgoCD       │  │    Prometheus    │           │  │
                              │  │  │    (GitOps)      │  │  Grafana, Loki   │           │  │
                              │  │  └──────────────────┘  └──────────────────┘           │  │
                              │  │                                                        │  │
                              │  │  ┌──────────────────┐  ┌──────────────────┐           │  │
                              │  │  │  Cert-Manager    │  │  External-DNS    │           │  │
                              │  │  │  (TLS Certs)     │  │  (DNS Records)   │           │  │
                              │  │  └──────────────────┘  └──────────────────┘           │  │
                              │  │                                                        │  │
                              │  │  ┌──────────────────┐  ┌──────────────────┐           │  │
                              │  │  │    Gatekeeper    │  │     Istio        │           │  │
                              │  │  │   (OPA Policy)   │  │  (Service Mesh)  │           │  │
                              │  │  └──────────────────┘  └──────────────────┘           │  │
                              │  └────────────────────────────────────────────────────────┘  │
                              │                                                              │
                              │  ┌───────────────────────────────────────────────────────┐  │
                              │  │                    VPC / VNet                          │  │
                              │  │            (Private Subnets, NAT Gateway)              │  │
                              │  └───────────────────────────────────────────────────────┘  │
                              └─────────────────────────────────────────────────────────────┘
```

## Platform Components

| Category      | Component        | Description                                 |
| ------------- | ---------------- | ------------------------------------------- |
| GitOps        | ArgoCD           | GitOps-based continuous deployment          |
| Observability | Prometheus       | Metrics collection and alerting             |
| Observability | Grafana          | Dashboards and visualization                |
| Observability | Loki             | Log aggregation                             |
| Service Mesh  | Istio            | Traffic management, security, observability |
| Ingress       | NGINX/Traefik    | HTTP(S) routing                             |
| TLS           | Cert-Manager     | Automatic TLS certificate management        |
| DNS           | External-DNS     | Automatic DNS record management             |
| Policy        | OPA Gatekeeper   | Policy enforcement                          |
| Security      | Network Policies | Pod-to-pod network segmentation             |

## Cloud Provider Support

| Provider | Kubernetes Service | Features                               |
| -------- | ------------------ | -------------------------------------- |
| AWS      | EKS                | IRSA, ALB Ingress, EBS CSI             |
| Azure    | AKS                | Pod Identity, Azure CNI, Managed Disks |
| GCP      | GKE                | Workload Identity, Cloud NAT, PD CSI   |

## Usage

1. Select cloud provider (AWS, Azure, or GCP)
2. Configure cluster size and node pools
3. Enable platform components (GitOps, Observability, etc.)
4. Deploy via Terraform

## Outputs

- Cluster endpoint and credentials
- ArgoCD URL (if enabled)
- Grafana URL (if enabled)
- kubectl configuration command
