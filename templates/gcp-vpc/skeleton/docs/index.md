# ${{ values.name }}

${{ values.description }}

## Overview

This GCP VPC Network is managed by Terraform for the **${{ values.environment }}** environment.

## Configuration

| Setting     | Value                     |
| ----------- | ------------------------- |
| Region      | ${{ values.region }}      |
| CIDR Range  | ${{ values.cidrRange }}   |
| GCP Project | ${{ values.gcpProject }}  |
| Environment | ${{ values.environment }} |

## Subnets

| Subnet  | Purpose                    | CIDR |
| ------- | -------------------------- | ---- |
| public  | Public-facing resources    | /24  |
| private | Private workloads          | /24  |
| gke     | GKE cluster nodes and pods | /20  |

## Features

- **Cloud NAT**: Outbound internet access for private resources
- **Cloud Router**: BGP routing for hybrid connectivity
- **Flow Logs**: Enabled on all subnets for monitoring
- **IAP SSH**: Firewall rule for secure SSH via Identity-Aware Proxy
- **GKE Ready**: Secondary IP ranges for pods and services

## Firewall Rules

| Rule           | Direction | Ports   | Source                   |
| -------------- | --------- | ------- | ------------------------ |
| allow-internal | Ingress   | All     | VPC CIDR                 |
| allow-iap-ssh  | Ingress   | 22      | IAP range                |
| allow-http     | Ingress   | 80, 443 | 0.0.0.0/0 (tagged)       |
| deny-all       | Ingress   | All     | 0.0.0.0/0 (low priority) |

## Usage

### Reference in Other Terraform

```hcl
data "google_compute_network" "main" {
  name    = "${{ values.name }}-${{ values.environment }}-vpc"
  project = "${{ values.gcpProject }}"
}

data "google_compute_subnetwork" "private" {
  name    = "${{ values.name }}-${{ values.environment }}-private"
  region  = "${{ values.region }}"
  project = "${{ values.gcpProject }}"
}
```

### VPC Peering

```hcl
resource "google_compute_network_peering" "peer" {
  name         = "peer-to-other"
  network      = google_compute_network.main.self_link
  peer_network = google_compute_network.other.self_link
}
```

## Owner

This resource is owned by **${{ values.owner }}**.
