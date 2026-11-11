# ${{ values.projectName }} infrastructure

GCP three-tier web application infrastructure for **${{ values.projectName }}** in the **${{ values.environment }}** environment, project `${{ values.gcpProjectId }}`, region `${{ values.region }}`.

## Architecture

```text
              Internet
                 |
{%- if values.enableCloudArmor %}
            Cloud Armor
                 |
{%- endif %}
  Global Application Load Balancer{% if values.enableCloudCdn %}  + Cloud CDN{% endif %}
                 |
{%- if values.computeType == 'gke-autopilot' %}
       GKE Autopilot cluster        VPC subnet, outbound through Cloud NAT
{%- elif values.computeType == 'gke-standard' %}
       GKE Standard cluster         VPC subnet, outbound through Cloud NAT
{%- else %}
     Managed instance group         VPC subnet, outbound through Cloud NAT
{%- endif %}
                 |
     Cloud SQL ${{ 'PostgreSQL' if values.databaseEngine == 'POSTGRES' else 'MySQL' }}           private address through private service access
```

## What was chosen

| Setting           | Value                                |
| ----------------- | ------------------------------------ |
| GCP project       | `${{ values.gcpProjectId }}`         |
| VPC CIDR          | `${{ values.vpcCidr }}`              |
| Compute type      | `${{ values.computeType }}`          |
{%- if values.computeType != 'gke-autopilot' %}
| Machine type      | `${{ values.machineType }}`          |
| Nodes             | ${{ values.minNodes }} to ${{ values.maxNodes }} |
{%- endif %}
| Database engine   | `${{ values.databaseEngine }}`       |
| Database tier     | `${{ values.databaseTier }}`         |
| High availability | ${{ 'yes' if values.highAvailability else 'no' }} |
| Cloud Armor       | ${{ 'yes' if values.enableCloudArmor else 'no' }} |
| Cloud CDN         | ${{ 'yes' if values.enableCloudCdn else 'no' }} |

These are the contents of `terraform.tfvars`. Change a value there and open a pull request to change the infrastructure.

## Components

- **APIs**: the Compute Engine, IAM, Secret Manager, Service Networking and Cloud SQL Admin APIs are enabled in the project, and the Kubernetes Engine API for the GKE compute types.
- **Network**: a VPC with one subnet in the region and VPC flow logs. `vpc_cidr` is split into the subnet, secondary ranges for GKE pods and services, and a range that is peered with Google's service network so Cloud SQL gets a private address. Nothing in the application tier has a public address; outbound traffic leaves through Cloud NAT. A firewall rule admits Google's load balancer and health check ranges on `container_port`.
- **Load balancer**: a global external Application Load Balancer with a static address. HTTP is redirected to HTTPS, and a TLS policy requires TLS 1.2 or newer. Until `domains` is set it uses a self-signed certificate, so browsers warn about the connection. Point your DNS names at the output `load_balancer_ip` and set `domains` to get a Google-managed certificate.
- **Application**: `compute_type` selects how the application runs.
    - `gke-autopilot`: a private GKE Autopilot cluster. Google adds and removes nodes to fit the pods, so there is no node count to set.
    - `gke-standard`: a private GKE Standard cluster with a node pool of `machine_type` nodes. The cluster autoscaler keeps the total number of nodes between `min_nodes` and `max_nodes`.
    - `mig`: a regional managed instance group of `machine_type` instances running `container_image` (a public nginx image by default) on Container-Optimized OS. CPU-based autoscaling keeps the group between `min_nodes` and `max_nodes` instances, and instances that fail the health check are replaced.
    - If `max_nodes` is lower than `min_nodes`, the autoscaler uses `min_nodes` for both bounds.
- **Database**: Cloud SQL with a private address only and TLS required. Backups and point-in-time recovery are on; `high_availability` adds a standby in a second zone. The application's database user gets a generated password that is stored in Secret Manager (output `database_password_secret_id`). The application's service account may read that secret and connect through the Cloud SQL Auth Proxy.
- **Cloud Armor**: when enabled, a security policy with Google's preconfigured rules against SQL injection, cross-site scripting, file inclusion and remote code execution, a per-address rate limit (`rate_limit_per_minute`) and adaptive protection is attached to the load balancer.
- **Cloud CDN**: when enabled, static responses are cached at Google's edge.

The network, service account and secret are built from the Terraform modules of [cloud-sandbox-backstage](https://github.com/ayoinc/cloud-sandbox-backstage/tree/main/catalog/terraform-modules/gcp/resources).

## Running the application on GKE

For the GKE compute types the stack creates the cluster and the load balancer; the application itself is deployed to the cluster with your usual tooling. Two settings connect it to the rest of the stack:

1. Expose the Deployment with a Service that asks GKE for a network endpoint group named after the output `gke_neg_name`:

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: app
      annotations:
        cloud.google.com/neg: '{"exposed_ports": {"80": {"name": "<gke_neg_name>"}}}'
    spec:
      type: ClusterIP
      selector:
        app: app
      ports:
        - port: 80
          targetPort: 80
    ```

    GKE creates one group per zone that runs pods. List those zones in `gke_neg_zones` in `terraform.tfvars` and apply; the load balancer then sends traffic straight to the pods. Until then it answers with 503. If the pods listen on another port, set `container_port` to it so the firewall admits the load balancer.

2. Run the pods with the Kubernetes service account `app` in the namespace `default` (variables `kubernetes_service_account` and `kubernetes_namespace`), annotated with `iam.gke.io/gcp-service-account: <app_service_account_email>`. Through Workload Identity the pods can then read the database password and connect to Cloud SQL.

The control plane accepts connections from inside the VPC only. Add your own address ranges to `gke_master_authorized_networks` to use `kubectl` from elsewhere.

## Pipeline

The **Terraform** workflow checks every push and pull request without needing a Google Cloud project: formatting, `terraform validate`, `terraform test` against mocked providers (`tests/stack.tftest.hcl`), TFLint and a Trivy scan for high and critical findings.

Plan and apply are skipped until these are set in the repository settings:

| Setting                          | Kind     | Purpose                                                 |
| -------------------------------- | -------- | ------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | secret   | Workload identity provider that trusts this repository  |
| `GCP_SERVICE_ACCOUNT`            | secret   | Service account the workflow acts as                    |
| `TF_STATE_BUCKET`                | variable | Cloud Storage bucket that holds the Terraform state     |
| `INFRACOST_API_KEY`              | secret   | Optional. Enables the cost estimate on pushes to `main` |

Every push to `main` then produces a plan. To apply, run the workflow from the Actions tab with **Apply** ticked.

## Outputs

| Output                        | Description                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| `load_balancer_ip`            | Public address of the load balancer                          |
| `network_name`                | Name of the VPC network                                      |
| `app_service_account_email`   | Service account the application runs as                      |
| `gke_cluster_name`            | GKE cluster, for the GKE compute types                       |
| `gke_neg_name`                | Name for the Service's network endpoint group, on GKE        |
| `instance_group`              | Managed instance group, for `mig`                            |
| `database_connection_name`    | Connection name for the Cloud SQL Auth Proxy                 |
| `database_private_ip`         | Private address of the database                              |
| `database_name`               | Name of the application's database                           |
| `database_username`           | Database user the application connects as                    |
| `database_password_secret_id` | Secret that holds the database user's password               |
| `security_policy_name`        | Cloud Armor policy, when Cloud Armor is enabled              |
