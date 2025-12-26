# ${{ values.name }}

${{ values.description }}

## Overview

This GKE cluster is managed by Terraform for the **${{ values.environment }}** environment using **${{ values.clusterMode }}** mode.

## Configuration

| Setting      | Value                                          |
| ------------ | ---------------------------------------------- |
| Cluster Mode | ${{ values.clusterMode }}                      |
| Region       | ${{ values.region }}                           |
| GCP Project  | ${{ values.gcpProject }}                       |
| Environment  | ${{ values.environment }}                      |
| Machine Type | ${{ values.machineType }} (Standard mode only) |
| Node Count   | ${{ values.nodeCount }} (Standard mode only)   |

## Features

- **Workload Identity**: Secure pod-level IAM authentication
- **Private Cluster**: Control plane and nodes in private network
- **Artifact Registry**: Container registry included
- **Shielded Nodes**: Secure boot and integrity monitoring
- **Auto-scaling**: Cluster autoscaler enabled
- **Release Channel**: Automatic Kubernetes upgrades

## Getting Started

### Get Credentials

```bash
gcloud container clusters get-credentials ${{ values.name }}-${{ values.environment }} \
  --region ${{ values.region }} \
  --project ${{ values.gcpProject }}
```

### Verify Connection

```bash
kubectl get nodes
kubectl get namespaces
```

### Push Image to Artifact Registry

```bash
# Configure Docker
gcloud auth configure-docker ${{ values.region }}-docker.pkg.dev

# Tag and push
docker tag myapp:latest ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/myapp:latest
docker push ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/myapp:latest
```

## Workload Identity

To allow pods to access GCP services:

```hcl
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project}.svc.id.goog[namespace/service-account-name]"
}
```

Then annotate your Kubernetes service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    iam.gke.io/gcp-service-account: app@project.iam.gserviceaccount.com
```

## Owner

This resource is owned by **${{ values.owner }}**.
