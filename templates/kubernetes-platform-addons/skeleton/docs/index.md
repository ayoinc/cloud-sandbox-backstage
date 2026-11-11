# ${{ values.name }}

${{ values.description }}

## What Is Installed

| Add-on         | Purpose                                                                                               |
| -------------- | ----------------------------------------------------------------------------------------------------- |
| Traefik        | Ingress controller and default IngressClass `traefik`; redirects HTTP to HTTPS; dashboard not exposed |
| cert-manager   | Issues and renews certificates; ClusterIssuers `letsencrypt-staging` and `letsencrypt-production`     |
| ExternalDNS    | Creates DNS records at ${{ values.dnsProvider }} for the hostnames of Ingress and Service resources{% if values.dnsDomain %} under `${{ values.dnsDomain }}`{% endif %} |
| Metrics Server | Resource metrics for the Horizontal Pod Autoscaler and `kubectl top`                                  |

Each add-on is a Helm release with a pinned chart version. Traefik, cert-manager and ExternalDNS get their own namespace, which enforces the *baseline* Pod Security Standard and reports anything short of *restricted*. In production every add-on runs two replicas with a pod disruption budget.

## Using the Add-ons

An Ingress like this gets a DNS record, a certificate and an HTTPS endpoint without further work:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
spec:
  ingressClassName: traefik
  tls:
    - hosts: [my-service.<your domain>]
      secretName: my-service-tls
  rules:
    - host: my-service.<your domain>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

Use `letsencrypt-staging` while trying things out: the production issuer is rate limited. The issuers answer the HTTP-01 challenge through Traefik, so the hostname must resolve to the load balancer of the cluster.

## Credentials

Nothing secret is stored in this repository.

| Secret           | Description                                                                 |
| ---------------- | --------------------------------------------------------------------------- |
| `KUBECONFIG_B64` | Base64-encoded kubeconfig of the cluster                                    |
| `DNS_API_TOKEN`  | API token of the DNS provider; only for `cloudflare` and `digitalocean`     |

The repository variable `TF_STATE_NAMESPACE` (default `kube-system`) names the namespace of the Secret that holds the Terraform state.

### Kubeconfig

Installing CRDs and cluster roles needs cluster-admin rights. Prefer credentials that expire:

```bash
kubectl -n kube-system create serviceaccount terraform
kubectl create clusterrolebinding terraform --clusterrole=cluster-admin --serviceaccount=kube-system:terraform

TOKEN=$(kubectl -n kube-system create token terraform --duration=720h)
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

kubectl config --kubeconfig=ci.kubeconfig set-cluster cluster --server="$SERVER"
kubectl config --kubeconfig=ci.kubeconfig set clusters.cluster.certificate-authority-data "$CA"
kubectl config --kubeconfig=ci.kubeconfig set-credentials terraform --token="$TOKEN"
kubectl config --kubeconfig=ci.kubeconfig set-context ci --cluster=cluster --user=terraform
kubectl config --kubeconfig=ci.kubeconfig use-context ci

base64 < ci.kubeconfig | tr -d '\n'   # value of KUBECONFIG_B64
rm ci.kubeconfig
```

The token expires after 30 days; renew the secret before then, or let a scheduled job do it. The pipeline writes the kubeconfig to the runner only while a job runs. A cluster that is not reachable from GitHub-hosted runners needs a self-hosted runner inside its network; change `runs-on` in the workflow.

### DNS Provider

| Provider                   | How ExternalDNS authenticates                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------------------------ |
| `cloudflare`               | API token with *Zone: Read* and *DNS: Edit* on the zone, in the secret `DNS_API_TOKEN`                 |
| `digitalocean`             | API token with the `domain` scopes, in the secret `DNS_API_TOKEN`                                      |
| `aws`, `google`, `azure`   | Workload identity of the cluster: put the role or identity annotation in `dns_service_account_annotations` |

The token is passed to Terraform as a write-only value: it is written to the Secret `external-dns-credentials` in the cluster and is stored neither in the plan nor in the Terraform state. After rotating the token, increase `dns_api_token_revision` so that the new value is written.

ExternalDNS starts with the `upsert-only` policy and never deletes a record. Switch `dns_policy` to `sync` once you are sure the zone holds no records that merely look like they belong to this cluster.

## Configuration

| Variable                              | Purpose                                                                    |
| ------------------------------------- | -------------------------------------------------------------------------- |
| `enable_ingress`, `enable_cert_manager`, `enable_external_dns`, `enable_metrics_server` | Switch add-ons on and off |
| `*_chart_version`                     | Pinned chart versions; upgrade one add-on at a time                        |
| `high_availability`                   | Two replicas and pod disruption budgets                                    |
| `ingress_service_annotations`         | Annotations of the load balancer Service (internal load balancer, type)    |
| `enable_gateway_api`                  | Serve Gateway API routes as well; the Gateway API CRDs must exist first    |
| `metrics_server_kubelet_insecure_tls` | For local clusters whose kubelets use self-signed certificates             |
| `kube_context`                        | Pin the kubeconfig context                                                 |

Managed clusters such as AKS, GKE and DOKS ship Metrics Server: keep `enable_metrics_server` off there.

## Upgrading an Add-on

Change its `*_chart_version` in `variables.tf` or the variable file, read the release notes of the chart, and push. Helm releases are atomic: a failed upgrade is rolled back. cert-manager's CRDs are kept when the release is removed, so certificates survive a reinstall.

## Pipeline

| Job             | Runs                                         | Needs the cluster |
| --------------- | -------------------------------------------- | ----------------- |
| Validate        | `terraform fmt -check`, `terraform validate` | No                |
| TFLint          | Lint rules in `.tflint.hcl`                  | No                |
| Terraform Tests | `terraform test` against mocked providers    | No                |
| Chart Lint      | `helm lint` and `helm template`              | No                |
| Security Scan   | Trivy and Checkov                            | No                |
| Plan, Apply     | On push to `main` and on demand              | Yes               |
| Destroy, Drift  | On demand from **Run workflow**              | Yes               |

## Provider Versions

`versions.tf` constrains the providers to a minor release line and `.terraform.lock.hcl` pins the exact releases, with checksums for Linux and macOS on x86-64 and Arm64. To upgrade:

```bash
terraform init -backend=false -upgrade
terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64
```
