# ${{ values.projectName }} infrastructure

Azure three-tier web application infrastructure for **${{ values.projectName }}** in the **${{ values.environment }}** environment, region `${{ values.location }}`.

## Architecture

```text
              Internet
                 |
{%- if values.enableFrontDoor %}
          Azure Front Door
                 |
{%- endif %}
{%- if values.enableWaf %}
   Application Gateway (WAF_v2)     gateway subnet
{%- else %}
 Application Gateway (Standard_v2)  gateway subnet
{%- endif %}
                 |
{%- if values.computeType == 'aks' %}
            AKS cluster             application subnet
{%- elif values.computeType == 'vmss' %}
     Virtual machine scale set      application subnet
{%- else %}
           Container App            application subnet
{%- endif %}
                 |
{%- if values.databaseType == 'sql-database' %}
       Azure SQL Database           data subnet
{%- elif values.databaseType == 'postgresql' %}
   PostgreSQL flexible server       data subnet
{%- else %}
            Cosmos DB               data subnet
{%- endif %}
```

## What was chosen

| Setting            | Value                                                          |
| ------------------ | -------------------------------------------------------------- |
| VNet address space | `${{ values.vnetAddressSpace }}`                               |
| Compute type       | `${{ values.computeType }}`                                    |
| VM size            | `${{ values.vmSize }}` (used by `aks` and `vmss`)              |
| Capacity           | ${{ values.minNodes }} to ${{ values.maxNodes }}               |
| Database type      | `${{ values.databaseType }}`                                   |
| Database SKU       | `${{ values.databaseSku }}`                                    |
| WAF                | ${{ 'yes' if values.enableWaf else 'no' }}                     |
| Front Door         | ${{ 'yes' if values.enableFrontDoor else 'no' }}               |

These are the contents of `terraform.tfvars`. Change a value there and open a pull request to change the infrastructure. When `max_nodes` is below `min_nodes`, the minimum is used for both. `database_sku` belongs to `database_type`: an Azure SQL Database SKU such as `GP_Gen5_2`, a PostgreSQL flexible server SKU such as `GP_Standard_D2s_v3`, or the Cosmos DB capacity mode `serverless` or `autoscale`.

## Components

- **Network**: a virtual network with a gateway subnet, an application subnet and a data subnet, each with its own network security group. The subnets are carved out of `vnet_address_space`, a private range of size /18 or larger. The data subnet accepts connections from the application subnet only.
- **Application Gateway**: the public entry point. `enable_waf` selects the WAF_v2 SKU with a firewall policy that applies the OWASP 3.2 rule set in Prevention mode; otherwise the gateway runs on Standard_v2. It serves HTTP until `tls_certificate_secret_id` points to a certificate in Key Vault; with a certificate it serves HTTPS and redirects HTTP. Grant the principal in the output `application_gateway_identity_principal_id` the Key Vault Secrets User role on the vault before setting the variable. Set a certificate before going live.
- **Application**: `compute_type` selects one of three.
    - `aks`: a private AKS cluster with one autoscaled node pool of `vm_size` nodes, between `min_nodes` and `max_nodes`. Access is granted through Microsoft Entra ID: list your administrator groups in `aks_admin_group_object_ids`. Set `aks_authorized_ip_ranges` to reach the API server from outside the virtual network, or use `az aks command invoke`. The gateway forwards requests to the address in the output `aks_ingress_ip`. Expose your ingress controller or service there (see below).
    - `vmss`: a scale set of `vm_size` Ubuntu virtual machines in the gateway's backend pool, autoscaled on CPU between `min_nodes` and `max_nodes`. They start nginx through cloud-init (`vmss_custom_data` replaces it) and reach the internet through a NAT gateway.
    - `container-apps`: a Container App running `container_image` in an environment that is reachable from the virtual network only, scaled on concurrent requests between `min_nodes` and `max_nodes` replicas. The container gets the address of the database in the environment variable `DATABASE_ENDPOINT`.
- **Database**: `database_type` selects one of three, none with a public endpoint.
    - `sql-database`: an Azure SQL server and database, reached through a private endpoint.
    - `postgresql`: a PostgreSQL flexible server in the delegated data subnet. Production gets a zone-redundant standby and geo-redundant backups. The server and its database have `prevent_destroy = true`; remove that line from `database.tf` before destroying the environment or changing `database_type`.
    - `cosmos-db`: a Cosmos DB account (NoSQL API) with one database, reached through a private endpoint.

    The administrator password of the SQL or PostgreSQL server is generated, kept in the Terraform state and available with `terraform output -raw database_admin_password`.
- **Front Door**: when enabled, a Standard profile uses the gateway's public address as its origin and serves HTTPS on its own domain. The gateway's network security group then admits Front Door only, and with WAF enabled the firewall policy rejects requests that do not carry the ID of this Front Door profile. Front Door talks HTTP to the gateway until the gateway has a certificate.
- **Monitoring**: a Log Analytics workspace receives the gateway's logs and metrics and the logs of the AKS cluster or the Container Apps environment.

The building blocks are the Terraform modules of [cloud-sandbox-backstage](https://github.com/ayoinc/cloud-sandbox-backstage/tree/main/catalog/terraform-modules/azure/resources).

### Exposing an application on AKS

The gateway expects the application behind an internal load balancer with the address of the output `aks_ingress_ip`, in the subnet of the output `aks_ingress_subnet_name`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: 'true'
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: <aks_ingress_subnet_name>
    service.beta.kubernetes.io/azure-load-balancer-ipv4: <aks_ingress_ip>
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
```

The service port is `app_port` (80 unless changed) and the gateway checks `health_check_path`.

## Pipeline

The **Terraform** workflow checks every push and pull request without needing an Azure subscription: formatting, `terraform validate`, `terraform test` against mocked providers (`tests/stack.tftest.hcl`), TFLint and a Trivy scan for high and critical findings.

Plan and apply are skipped until these are set in the repository settings:

| Setting                    | Kind     | Purpose                                                              |
| -------------------------- | -------- | -------------------------------------------------------------------- |
| `AZURE_CLIENT_ID`          | secret   | Application the workflow signs in as through GitHub OIDC             |
| `AZURE_TENANT_ID`          | secret   | Microsoft Entra tenant of that application                           |
| `AZURE_SUBSCRIPTION_ID`    | secret   | Subscription the stack is deployed to                                |
| `TF_STATE_RESOURCE_GROUP`  | variable | Resource group of the storage account that holds the Terraform state |
| `TF_STATE_STORAGE_ACCOUNT` | variable | That storage account. The state is kept in its container `tfstate`   |
| `INFRACOST_API_KEY`        | secret   | Optional. Enables the cost estimate on pushes to `main`              |

Every push to `main` then produces a plan. To apply, run the workflow from the Actions tab with **Apply** ticked.

## Outputs

| Output                                      | Description                                                   |
| ------------------------------------------- | ------------------------------------------------------------- |
| `application_url`                           | Address the application is served at                          |
| `application_gateway_public_ip`             | Public address of the Application Gateway                     |
| `application_gateway_identity_principal_id` | Principal that reads the gateway's certificate from Key Vault |
| `front_door_host_name`                      | Front Door endpoint, when Front Door is enabled               |
| `aks_cluster_name`                          | AKS cluster, for `aks`                                        |
| `aks_ingress_ip`, `aks_ingress_subnet_name` | Where the gateway expects the cluster's ingress, for `aks`    |
| `vmss_name`                                 | Scale set, for `vmss`                                         |
| `vmss_admin_private_key`                    | Generated SSH key of the scale set administrator, for `vmss`  |
| `container_app_fqdn`                        | Name of the Container App, for `container-apps`               |
| `database_endpoint`, `database_name`        | Where the database is reached                                 |
| `database_admin_username`                   | Administrator login of the SQL or PostgreSQL server           |
| `database_admin_password`                   | Its generated password (sensitive)                            |
| `resource_group_name`, `vnet_id`, `subnet_ids`, `log_analytics_workspace_id` | Shared resources             |
