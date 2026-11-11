# ${{ values.projectName }} Kubernetes platform

Azure Kubernetes Service (AKS) cluster with platform components for **${{ values.projectName }}** in the **${{ values.environment }}** environment, region `${{ values.azureRegion }}`.

## Architecture

```text
                 Internet
                    |
{%- if values.enableIngress == 'nginx' %}
       public Azure load balancer
                    |
      ingress-nginx controller
                    |
{%- elif values.enableIngress == 'traefik' %}
       public Azure load balancer
                    |
      Traefik ingress controller
                    |
{%- else %}
   no ingress controller, nothing is published
                    |
{%- endif %}
   AKS cluster with the platform components       Kubernetes ${{ values.kubernetesVersion }}
   one autoscaled node pool                       `${{ values.nodeSize }}` nodes in three availability zones
   pods on an overlay network                     {% if values.enableNetworkPolicies %}network policies enforced by Cilium{% else %}no network policy engine{% endif %}
                    |
   node subnet of the virtual network             outbound traffic through the cluster's load balancer
                    |
   control plane logs in a Log Analytics workspace
```

## What was chosen

| Setting                  | Value                                                            |
| ------------------------ | ---------------------------------------------------------------- |
| Region                   | `${{ values.azureRegion }}`                                      |
| Subscription             | {% if values.azureSubscriptionId %}`${{ values.azureSubscriptionId }}`{% else %}the subscription of the pipeline's credentials{% endif %} |
| Kubernetes version       | ${{ values.kubernetesVersion }}                                  |
| Nodes                    | ${{ values.minNodes }} to ${{ values.maxNodes }}, size `${{ values.nodeSize }}` |
| GitOps (Argo CD)         | ${{ 'yes' if values.enableGitOps else 'no' }}                    |
| Observability stack      | ${{ 'yes' if values.enableObservability else 'no' }}             |
| Service mesh (Istio)     | ${{ 'yes' if values.enableServiceMesh else 'no' }}               |
| cert-manager             | ${{ 'yes' if values.enableCertManager else 'no' }}               |
| external-dns             | ${{ 'yes' if values.enableExternalDns else 'no' }}               |
| Ingress controller       | `${{ values.enableIngress }}`                                    |
| Pod Security Standards   | ${{ 'yes' if values.enablePodSecurityPolicies else 'no' }}       |
| Network policies         | ${{ 'yes' if values.enableNetworkPolicies else 'no' }}           |
| OPA Gatekeeper           | ${{ 'yes' if values.enableOPA else 'no' }}                       |
| Vault integration        | ${{ 'yes' if values.enableVaultIntegration else 'no' }}          |

These are the contents of `terraform.tfvars`. Change a value there and open a pull request to change the infrastructure.

## Components

- **Resource group**: `rg-${{ values.projectName }}-<environment>-${{ values.azureRegion }}` holds everything this stack creates. In resource names the production environment is abbreviated to `prod`.
- **Network**: a virtual network (`vnet_cidr`, 10.40.0.0/16 by default) whose first /20 is the subnet of the nodes. Pods take their addresses from an overlay range (`pod_cidr`) that is not part of the virtual network, so the cluster does not use up subnet addresses. The network security group of the subnet allows traffic between nodes and pods and, when an ingress controller is installed, ports 80 and 443 from the internet. Outbound traffic leaves through the cluster's load balancer.
- **Cluster**: AKS with one node pool that the cluster autoscaler keeps between `node_min_count` and `node_max_count` nodes, spread over the availability zones in `availability_zones`. A `node_max_count` below `node_min_count` counts as `node_min_count`. `node_size` selects the VM size: `small` is Standard_D2ls_v5 (2 vCPU, 4 GiB), `medium` Standard_D4s_v5 (4 vCPU, 16 GiB), `large` Standard_D8s_v5 (8 vCPU, 32 GiB). `kubernetes_version` is a minor version; AKS installs its latest patch release and later ones automatically. Whether AKS offers a minor version in the region is shown by `az aks get-versions --location ${{ values.azureRegion }}`. Production uses the Standard tier with the uptime SLA, other environments the Free tier.
- **Access**: people sign in with Microsoft Entra ID (`az aks get-credentials`, then `kubelogin`). Put the object IDs of your administrators' groups in `cluster_admin_group_object_ids`, or assign the role Azure Kubernetes Service RBAC Cluster Admin on the cluster. The API server is reachable from every address until `api_server_authorized_ip_ranges` is set; the pipeline's runners must stay inside those ranges. Terraform itself installs the platform components with the cluster's administrator certificate.
- **Network policies**: when enabled, the cluster runs the Cilium data plane (Azure CNI powered by Cilium), which enforces Kubernetes NetworkPolicy objects, and the platform namespaces get default-deny policies. With Cilium an `ipBlock` rule cannot select the addresses of pods or nodes; use pod and namespace selectors for traffic inside the cluster. When disabled, the cluster has no policy engine and NetworkPolicy objects have no effect. The data plane is chosen when the cluster is created: changing `enable_network_policies` afterwards replaces the cluster.
- **Workload identity**: the cluster has an OIDC issuer (output `cluster_oidc_issuer_url`) and the workload identity webhook, so a Kubernetes service account can sign in as a managed identity without a secret.
- **external-dns identity**: when external-dns is enabled, a managed identity federated with the service account `external-dns` in namespace `external-dns` gets the role DNS Zone Contributor on a resource group: this stack's own, or the one named in `dns_zone_resource_group`. Create or delegate your Azure DNS zone in that resource group; limit the zones external-dns touches with `dns_domain_filters`.
- **Ingress**: the ingress controller is published through a public Azure load balancer. `none` installs no controller and keeps the node subnet closed to the internet.
- **Storage**: persistent volumes of the platform use the `managed-csi` storage class (Standard SSD managed disks).
- **Logs**: the logs of the managed control plane (API server, administrative audit events, controller manager, scheduler, cluster autoscaler, Entra ID sign-ins) go to the Log Analytics workspace `log-${{ values.projectName }}-<environment>-${{ values.azureRegion }}`, kept for 90 days in production and 30 days elsewhere.

The components installed into the cluster are described in [Platform components](components.md).

The building blocks are the Terraform modules of [cloud-sandbox-backstage](https://github.com/ayoinc/cloud-sandbox-backstage/tree/main/catalog/terraform-modules/azure/resources).

## Pipeline

The **Terraform** workflow checks every push and pull request without needing an Azure subscription: formatting, `terraform validate`, `terraform test` against mocked providers (`tests/stack.tftest.hcl`), TFLint and a Trivy scan for high and critical findings.

Plan and apply are skipped until these are set in the repository settings:

| Setting                    | Kind     | Purpose                                                              |
| -------------------------- | -------- | -------------------------------------------------------------------- |
| `AZURE_CLIENT_ID`          | secret   | Application or managed identity the workflow signs in as through GitHub OIDC |
| `AZURE_TENANT_ID`          | secret   | Microsoft Entra ID tenant of that identity                           |
| `AZURE_SUBSCRIPTION_ID`    | secret   | Subscription of that identity                                        |
| `TF_STATE_RESOURCE_GROUP`  | variable | Resource group of the storage account that holds the Terraform state |
| `TF_STATE_STORAGE_ACCOUNT` | variable | Storage account with the container `tfstate`                         |
| `INFRACOST_API_KEY`        | secret   | Optional. Enables the cost estimate on pushes to `main`              |

The identity needs a federated credential for this repository, the role Owner (or Contributor together with Role Based Access Control Administrator) on the subscription the stack is created in, because the stack assigns roles to the identities it creates, and Storage Blob Data Contributor on the state container.{% if values.azureSubscriptionId %} The resources are created in subscription `${{ values.azureSubscriptionId }}` (`subscription_id` in `terraform.tfvars`), whatever `AZURE_SUBSCRIPTION_ID` says.{% endif %}

Every push to `main` then produces a plan. To apply, run the workflow from the Actions tab with **Apply** ticked. The first apply creates the cluster and then installs the components, which takes 15 to 30 minutes.

## Outputs

| Output                            | Description                                                    |
| --------------------------------- | -------------------------------------------------------------- |
| `resource_group_name`             | Resource group that holds the stack                            |
| `cluster_name`                    | Name of the AKS cluster                                        |
| `cluster_kubernetes_version`      | Kubernetes version the cluster runs, with its patch release    |
| `get_credentials_command`         | Command that adds the cluster to the local kubeconfig          |
| `cluster_oidc_issuer_url`         | OIDC issuer for further workload identities                    |
| `node_resource_group_name`        | Resource group in which AKS keeps nodes, load balancers, disks |
| `virtual_network_id`              | Virtual network of the cluster                                 |
| `node_subnet_id`                  | Subnet of the nodes                                            |
| `log_analytics_workspace_id`      | Workspace that receives the control plane logs                 |
| `external_dns_identity_client_id` | Managed identity of external-dns, when it is enabled           |
| `dns_zone_resource_group`         | Resource group whose DNS zones external-dns manages            |
