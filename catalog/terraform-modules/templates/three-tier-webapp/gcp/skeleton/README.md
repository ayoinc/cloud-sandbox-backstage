# GCP 3-Tier Web Application Infrastructure

Production-ready 3-tier architecture with Cloud Load Balancer, GKE/MIG, and Cloud SQL on Google Cloud Platform.

## Architecture

```
                                    ┌─────────────────────────────────────────────────────┐
                                    │                   Google Cloud                       │
                                    │                                                      │
┌──────────┐                        │  ┌────────────────────────────────────────────────┐ │
│          │    HTTPS               │  │              Cloud Armor (WAF)                  │ │
│  Users   │──────────────────────▶│  │  ┌──────────────────────────────────────────┐  │ │
│          │                        │  │  │         Global Load Balancer              │  │ │
└──────────┘                        │  │  │           (HTTPS/HTTP)                    │  │ │
                                    │  │  └─────────────────┬────────────────────────┘  │ │
                                    │  └────────────────────┼────────────────────────────┘ │
                                    │                       │                              │
                                    │  ┌────────────────────▼────────────────────────────┐ │
                                    │  │                  VPC Network                     │ │
                                    │  │                                                  │ │
                                    │  │  ┌──────────────────────────────────────────┐  │ │
                                    │  │  │            Compute (GKE/MIG)              │  │ │
                                    │  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐     │  │ │
                                    │  │  │  │  Pod/   │ │  Pod/   │ │  Pod/   │     │  │ │
                                    │  │  │  │   VM    │ │   VM    │ │   VM    │     │  │ │
                                    │  │  │  └────┬────┘ └────┬────┘ └────┬────┘     │  │ │
                                    │  │  └───────┼──────────┼──────────┼──────────┘  │ │
                                    │  │          │          │          │              │ │
                                    │  │  ┌───────▼──────────▼──────────▼──────────┐  │ │
                                    │  │  │              Cloud SQL                   │  │ │
                                    │  │  │      (PostgreSQL / MySQL)                │  │ │
                                    │  │  │           Private IP                     │  │ │
                                    │  │  └──────────────────────────────────────────┘  │ │
                                    │  └──────────────────────────────────────────────────┘ │
                                    │                                                      │
                                    │  ┌──────────────────────────────────────────────────┐ │
                                    │  │              Secret Manager                       │ │
                                    │  │        (Database Credentials)                     │ │
                                    │  └──────────────────────────────────────────────────┘ │
                                    └─────────────────────────────────────────────────────┘
```

## Components

| Layer | Component | Description |
|-------|-----------|-------------|
| Edge | Cloud Armor | WAF and DDoS protection |
| Edge | Global Load Balancer | HTTPS/HTTP traffic distribution |
| Compute | GKE Autopilot | Serverless Kubernetes (default) |
| Compute | GKE Standard | Standard Kubernetes cluster |
| Compute | Managed Instance Group | VM-based compute |
| Database | Cloud SQL | Managed PostgreSQL/MySQL |
| Security | Secret Manager | Secrets storage |
| Network | VPC | Private networking with Cloud NAT |

## Usage

1. Select this template in Backstage
2. Configure your project settings
3. Choose compute type (GKE Autopilot, GKE Standard, or MIG)
4. Configure database settings
5. Enable/disable optional features

## Prerequisites

- GCP Project with billing enabled
- Terraform >= 1.0
- gcloud CLI configured

## Outputs

After deployment, you'll receive:
- Load Balancer IP address
- Cluster credentials (for GKE)
- Database connection string
- Cloud Armor policy ID (if enabled)
