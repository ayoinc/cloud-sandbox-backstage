# ${{ values.name }}

${{ values.description }}

## Architecture

| Resource                           | Purpose                                                                       |
| ---------------------------------- | ----------------------------------------------------------------------------- |
| `digitalocean_vpc`                 | Private network of the cluster, one address range per environment             |
| `digitalocean_kubernetes_cluster`  | DOKS cluster `${{ values.name }}-<environment>` on Kubernetes ${{ values.kubernetesVersion }} in `${{ values.region }}` |
| Default node pool                  | Autoscaling pool; further pools are declared in `additional_node_pools`       |
| `digitalocean_container_registry`  | {% if values.registry == 'create' %}Created in ${{ values.envName }} and integrated with every cluster{% elif values.registry == 'integrate' %}Not created; the cluster is integrated with the registry of the account{% else %}Not used{% endif %} |
| `digitalocean_project`             | Groups the cluster in the control panel and on the invoice                    |

Patch releases are installed automatically in the weekly maintenance window, with surge upgrades so capacity is added before nodes are drained.

## Credentials

Nothing secret is stored in this repository. The pipeline reads these repository secrets:

| Secret                     | Description                                             |
| -------------------------- | ------------------------------------------------------- |
| `DIGITALOCEAN_TOKEN`       | API token with the scopes below                         |
| `SPACES_ACCESS_KEY_ID`     | Spaces access key for the state bucket                  |
| `SPACES_SECRET_ACCESS_KEY` | Secret of that access key                               |
| `TF_STATE_BUCKET`          | Name of the Spaces bucket that holds the Terraform state |

Token scopes: `kubernetes` (all), `vpc` (all), `project` (all), `registry` (all), `tag` (create, read) and `droplet`, `load_balancer`, `block_storage` (read).

### API Token

Create a custom-scoped token under **API > Tokens** with the scopes listed above and an expiry date. DigitalOcean does not issue short-lived credentials to GitHub Actions, so rotate the token before it expires.

### State Bucket

Create a private Spaces bucket in the region of this project and a Spaces access key limited to that bucket (**Spaces Object Storage > Access Keys > Limited Access**). The key pair is the two `SPACES_*` secrets. If the bucket is in another region than `${{ values.region }}`, set the repository variable `TF_STATE_REGION` to it.

The pipeline runs one Terraform job per branch at a time, which keeps two runs from writing the state together; do not apply from a workstation while the pipeline runs.

## Access to the Cluster

```bash
doctl kubernetes cluster kubeconfig save ${{ values.name }}-${{ values.envName }}
```

`doctl` writes a kubeconfig that fetches short-lived credentials on demand; no long-lived certificate ends up on the workstation. Access follows the team roles of the DigitalOcean account.

To restrict the Kubernetes API to known networks, list them in `control_plane_allowed_cidrs`. Include the addresses of the systems that deploy to the cluster.

## Node Pools

```hcl
additional_node_pools = {
  batch = {
    size      = "c-4"
    min_nodes = 0
    max_nodes = 4
    labels    = { workload = "batch" }
    taints    = [{ key = "workload", value = "batch", effect = "NoSchedule" }]
  }
}
```

## Container Registry

With `registry_integration = true` DigitalOcean adds an image pull secret to every namespace, so pods pull from the registry of the account without further configuration. A registry must exist before the first apply; `create_registry` creates it.

## Upgrading Kubernetes

Change `kubernetes_version` to the next minor version, one step at a time, and push. Check `doctl kubernetes options versions` for the versions on offer.

## Pipeline

| Job             | Runs                                         | Needs credentials |
| --------------- | -------------------------------------------- | ----------------- |
| Validate        | `terraform fmt -check`, `terraform validate` | No                |
| TFLint          | Lint rules in `.tflint.hcl`                  | No                |
| Terraform Tests | `terraform test` against a mocked provider   | No                |
| Security Scan   | Trivy and Checkov                            | No                |
| Plan, Apply     | On push to `main` and on demand              | Yes               |
| Destroy, Drift  | On demand from **Run workflow**              | Yes               |

A push to `main` plans and applies the `${{ values.envName }}` environment. Drift detection opens an issue when the infrastructure no longer matches the configuration.

## Provider Versions

`versions.tf` constrains the providers to a minor release line and `.terraform.lock.hcl` pins the exact releases, with checksums for Linux and macOS on x86-64 and Arm64. To upgrade:

```bash
terraform init -backend=false -upgrade
terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64
```
