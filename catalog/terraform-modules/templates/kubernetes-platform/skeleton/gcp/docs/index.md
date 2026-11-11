# ${{ values.projectName }} Kubernetes platform

Kubernetes platform for **${{ values.projectName }}** in the **${{ values.environment }}** environment, on Google Kubernetes Engine in region `${{ values.gcpRegion }}` of project `${{ values.gcpProjectId }}`.

This page describes the cluster and its Google Cloud resources. The components installed into the cluster are described in [Platform components](components.md).

## Architecture

```text
                         Internet
                            |
{%- if values.enableIngress != 'none' %}
          external passthrough Network Load Balancer
                            |
{%- else %}
                   (no ingress controller)
                            |
{%- endif %}
   +------------------------------------------------+
   | GKE cluster ${{ values.projectName }}-${{ values.environment }}-gke
   |   regional control plane, DNS-based endpoint
   |   node pool, ${{ values.minNodes }} to ${{ values.maxNodes if values.maxNodes >= values.minNodes else values.minNodes }} ${{ values.nodeSize }} nodes     private nodes, three zones
{%- if values.enableNetworkPolicies %}
   |   GKE Dataplane V2, Workload Identity
{%- else %}
   |   Workload Identity
{%- endif %}
   |   platform components
   +------------------------------------------------+
                            |
                        Cloud NAT                     outbound traffic of nodes and pods
```

## What was chosen

| Setting              | Value                                                  |
| -------------------- | ------------------------------------------------------ |
| Environment          | `${{ values.environment }}`                            |
| Project              | `${{ values.gcpProjectId }}`                           |
| Region               | `${{ values.gcpRegion }}`                              |
| Kubernetes version   | `${{ values.kubernetesVersion }}`                      |
| Nodes                | ${{ values.minNodes }} to ${{ values.maxNodes if values.maxNodes >= values.minNodes else values.minNodes }}, over all zones |
| Node size            | `${{ values.nodeSize }}` ({% if values.nodeSize == 'small' %}`e2-custom-2-4096`, 2 vCPU, 4 GB{% elif values.nodeSize == 'medium' %}`e2-standard-4`, 4 vCPU, 16 GB{% else %}`e2-standard-8`, 8 vCPU, 32 GB{% endif %}) |
| GitOps (Argo CD)     | ${{ 'yes' if values.enableGitOps else 'no' }}          |
| Observability stack  | ${{ 'yes' if values.enableObservability else 'no' }}   |
| Service mesh (Istio) | ${{ 'yes' if values.enableServiceMesh else 'no' }}     |
| cert-manager         | ${{ 'yes' if values.enableCertManager else 'no' }}     |
| external-dns         | ${{ 'yes' if values.enableExternalDns else 'no' }}     |
| Ingress controller   | `${{ values.enableIngress }}`                          |
| Pod Security Standards | ${{ 'yes' if values.enablePodSecurityPolicies else 'no' }} |
| Network policies     | ${{ 'yes' if values.enableNetworkPolicies else 'no' }} |
| OPA Gatekeeper       | ${{ 'yes' if values.enableOPA else 'no' }}             |
| Vault integration    | ${{ 'yes' if values.enableVaultIntegration else 'no' }} |

These are the contents of `terraform.tfvars`. Change a value there and open a pull request to change the platform.

## Google Cloud resources

- **APIs** (`main.tf`): Compute Engine, Kubernetes Engine, IAM, IAM Service Account Credentials, Cloud Resource Manager, Cloud Logging and Cloud Monitoring are enabled in the project{% if values.enableExternalDns %}, and Cloud DNS for external-dns{% endif %}. They stay enabled when the stack is destroyed.
- **Network** (`network.tf`): a VPC with one subnet in `${{ values.gcpRegion }}`. Nodes take their addresses from the primary range `10.0.0.0/20`, pods from the secondary range `10.4.0.0/14` and Services from `10.8.0.0/20`. Flow logs are on for the subnet. Nodes have no public addresses; a Cloud Router with Cloud NAT gives nodes and pods outbound access, for example to pull images.
- **Control plane** (`cluster.tf`): a regional GKE Standard cluster, with the control plane and the nodes spread over three zones. It is created with the newest patch release of Kubernetes `${{ values.kubernetesVersion }}`; GKE then keeps the control plane and the nodes up to date within the release channel, in a daily maintenance window that starts at 02:00 UTC. System and workload logs go to Cloud Logging, system metrics to Cloud Monitoring.{% if not values.enableObservability %} Google Cloud Managed Service for Prometheus collects workload metrics, because the observability stack is not installed.{% endif %}
- **API endpoint**: the IP-based endpoint of the control plane is private and reachable only from inside the VPC. From everywhere else, including the pipeline, the Kubernetes API is reached through the DNS-based endpoint of the cluster. Google Cloud admits a request there only when the caller has the IAM permission `container.clusters.connect` on the cluster.
- **Nodes**: one node pool on Container-Optimized OS with Shielded VM features. `node_size` selects the machine type: `small` is `e2-custom-2-4096`, `medium` is `e2-standard-4`, `large` is `e2-standard-8`. The GKE cluster autoscaler adds nodes when pods do not fit and removes unused nodes. `node_min_count` and `node_max_count` are limits for the whole pool, which GKE balances over the three zones. A `node_max_count` below `node_min_count` counts as `node_min_count`. The pool is created with the same number of nodes in every zone, enough to reach `node_min_count`, so it starts with at least three nodes; the autoscaler then removes the nodes that are not needed. Nodes are repaired and upgraded automatically, one extra node at a time.
- **Network policies**: {% if values.enableNetworkPolicies %}the cluster uses GKE Dataplane V2, which enforces `NetworkPolicy` objects.{% else %}the cluster uses kube-proxy, so `NetworkPolicy` objects are not enforced.{% endif %} The data plane is chosen when the cluster is created: changing `enable_network_policies` later makes Terraform replace the cluster.
- **Firewall**: GKE lets the control plane reach the nodes on ports 443 and 10250. One more rule opens the ports the admission webhooks of the platform components listen on (`control_plane_webhook_ports`).
- **Storage**: persistent volumes use the StorageClass `standard-rwo` that GKE provides: balanced persistent disks, created in the zone of the pod that first uses the claim.
- **Load balancer**: the Service of the ingress controller is annotated so that GKE creates an external passthrough Network Load Balancer with a regional backend service.
- **Identity** (`identity.tf`): the nodes run as their own service account, which can write logs and metrics and pull images from Artifact Registry. Workload Identity lets a Kubernetes service account act as a Google service account without keys.{% if values.enableExternalDns %} The Kubernetes service account `external-dns` in namespace `external-dns` acts as a Google service account with the role `roles/dns.admin`, so external-dns can change records in the Cloud DNS zones of the project.{% endif %}

The network and the service accounts are built with the Terraform modules of [cloud-sandbox-backstage](https://github.com/ayoinc/cloud-sandbox-backstage/tree/main/catalog/terraform-modules/gcp/resources). The cluster and its node pool are declared in this repository.

While the cluster is created, GKE starts a temporary default node pool of one node per zone and removes it again; the nodes of the platform are in the node pool `primary`.

## Access to the cluster

Access is granted with IAM roles on the project, for example `roles/container.viewer`, `roles/container.developer` or `roles/container.admin`. A user with one of them connects with:

```bash
gcloud container clusters get-credentials ${{ values.projectName }}-${{ values.environment }}-gke \
  --location ${{ values.gcpRegion }} --project ${{ values.gcpProjectId }} --dns-endpoint
kubectl get nodes
```

To give a workload access to Google Cloud, create a Google service account, grant `roles/iam.workloadIdentityUser` on it to `serviceAccount:${{ values.gcpProjectId }}.svc.id.goog[<namespace>/<service account>]` and annotate the Kubernetes service account with `iam.gke.io/gcp-service-account: <email of the Google service account>`.

## Settings that are not in the form

Set these in `terraform.tfvars` when the default does not fit.

| Variable                      | Default                     | Purpose                                                                  |
| ----------------------------- | --------------------------- | ------------------------------------------------------------------------ |
| `subnet_cidr`                 | `10.0.0.0/20`               | Primary range of the subnet, used by the nodes                           |
| `pods_cidr`                   | `10.4.0.0/14`               | Secondary range for pods; every node takes a `/24` of it                 |
| `services_cidr`               | `10.8.0.0/20`               | Secondary range for Services                                             |
| `master_ipv4_cidr_block`      | `172.16.0.0/28`             | Range of the internal endpoint of the control plane                      |
| `control_plane_webhook_ports` | `["8443", "9443", "15017"]` | Ports on the nodes the control plane may call admission webhooks on      |
| `release_channel`             | `null`                      | `RAPID`, `REGULAR`, `STABLE` or `EXTENDED`; when null GKE picks the most mature channel that offers the Kubernetes version |
| `maintenance_start_time`      | `02:00`                     | Start of the daily four-hour maintenance window, in UTC                  |
| `node_disk_size_gb`           | `100`                       | Boot disk of every node                                                  |

The address ranges cannot be changed after the cluster is created. The settings of the platform components are listed in [Platform components](components.md).

## Pipeline

The **Terraform** workflow checks every push and pull request without needing a Google Cloud project: formatting, `terraform validate`, `terraform test` against mocked providers (`tests/stack.tftest.hcl`), TFLint and a Trivy scan for high and critical findings.

Plan and apply are skipped until these are set in the repository settings:

| Setting                          | Kind     | Purpose                                                 |
| -------------------------------- | -------- | ------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | secret   | Workload identity provider that trusts this repository  |
| `GCP_SERVICE_ACCOUNT`            | secret   | Service account the workflow acts as                    |
| `TF_STATE_BUCKET`                | variable | Cloud Storage bucket that holds the Terraform state     |
| `INFRACOST_API_KEY`              | secret   | Optional. Enables the cost estimate on pushes to `main` |

Every push to `main` then produces a plan. To apply, run the workflow from the Actions tab with **Apply** ticked. The first apply creates the network, the cluster, the nodes and then the platform components, and takes about half an hour.

The service account in `GCP_SERVICE_ACCOUNT` needs these roles on the project `${{ values.gcpProjectId }}`, and `roles/storage.objectAdmin` on the state bucket:

| Role                                      | Used for                                                   |
| ----------------------------------------- | ---------------------------------------------------------- |
| `roles/serviceusage.serviceUsageAdmin`    | Enabling the APIs                                          |
| `roles/compute.networkAdmin`              | VPC, subnet, Cloud Router, Cloud NAT                       |
| `roles/compute.securityAdmin`             | Firewall rules                                             |
| `roles/container.admin`                   | The cluster, its node pool and the objects inside it       |
| `roles/iam.serviceAccountAdmin`           | Service accounts and their Workload Identity bindings      |
| `roles/iam.serviceAccountUser`            | Running the nodes as their service account                 |
| `roles/resourcemanager.projectIamAdmin`   | Granting roles to the service accounts of the stack        |

The Service Usage API must already be enabled in the project, which is the case for projects created in the console or with `gcloud`.

## Upgrading and removing

- **Kubernetes version**: `kubernetes_version` is the lowest version the control plane may run. GKE upgrades the cluster by itself within its release channel; raise `kubernetes_version` one minor version at a time to move to a newer minor version before GKE does. The nodes follow the control plane.
- **Production**: the production cluster has deletion protection. To remove it, set `deletion_protection = false` on the cluster in `cluster.tf`, apply, and then destroy.
- **Removing the stack**: delete the PersistentVolumeClaims and the Services of type `LoadBalancer` that were created outside this stack before `terraform destroy`; their disks and load balancers otherwise remain in the project and block the removal of the VPC.

## Outputs

| Output                               | Description                                                  |
| ------------------------------------ | ------------------------------------------------------------ |
| `cluster_name`                       | Name of the GKE cluster                                      |
| `cluster_location`                   | Region of the GKE cluster                                    |
| `cluster_endpoint`                   | DNS-based endpoint of the Kubernetes API                     |
| `cluster_version`                    | Kubernetes version the control plane runs                    |
| `get_credentials_command`            | Command that adds the cluster to the local kubeconfig        |
| `network_name`                       | Name of the VPC network                                      |
| `subnet_id`                          | ID of the cluster subnet                                     |
| `node_machine_type`                  | Machine type of the nodes                                    |
| `node_service_account_email`         | Service account the nodes run as                             |
| `workload_identity_pool`             | Workload identity pool, for IAM members of Kubernetes service accounts |
| `external_dns_service_account_email` | Google service account of external-dns, when it is enabled   |
| `storage_class`                      | Name of the StorageClass the platform components use         |
