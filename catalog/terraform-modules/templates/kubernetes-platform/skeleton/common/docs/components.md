# Platform components

The cluster is delivered with a set of platform components. Terraform installs them with Helm right after the cluster is ready (`platform.tf` and `platform-*.tf`), in namespaces it creates itself. Each component is switched by one value in `terraform.tfvars`; change the value, open a pull request, and the pipeline's plan shows what will be installed or removed.

How to get `kubectl` access to the cluster is described in the [Overview](index.md).

## What this repository was created with

| Component                         | Setting in `terraform.tfvars`   | Value                                                |
| --------------------------------- | ------------------------------- | ---------------------------------------------------- |
| GitOps (Argo CD)                  | `enable_gitops`                 | ${{ 'on' if values.enableGitOps else 'off' }}              |
| Observability (Prometheus, Grafana, Loki) | `enable_observability`  | ${{ 'on' if values.enableObservability else 'off' }}       |
| Service mesh (Istio)              | `enable_service_mesh`           | ${{ 'on' if values.enableServiceMesh else 'off' }}         |
| cert-manager                      | `enable_cert_manager`           | ${{ 'on' if values.enableCertManager else 'off' }}         |
| external-dns                      | `enable_external_dns`           | ${{ 'on' if values.enableExternalDns else 'off' }}         |
| Ingress controller                | `ingress_controller`            | ${{ values.enableIngress }}                                |
| Pod Security Standards            | `enable_pod_security_standards` | ${{ 'on' if values.enablePodSecurityPolicies else 'off' }} |
| Network policies                  | `enable_network_policies`       | ${{ 'on' if values.enableNetworkPolicies else 'off' }}     |
| OPA Gatekeeper                    | `enable_opa`                    | ${{ 'on' if values.enableOPA else 'off' }}                 |
| Vault integration                 | `enable_vault_integration`      | ${{ 'on' if values.enableVaultIntegration else 'off' }}    |

The sections below describe the components that are switched on. A component that is off has no namespace, no Helm release and no network policy; switching it on later adds them, and this page lists every component with its chart at the end.

`terraform output platform_chart_versions`, `platform_namespaces` and `platform_services` show what is installed at any time.
{%- if values.enableGitOps %}

## GitOps: Argo CD

- **Installed:** chart `argo-cd` 10.17.1 (Argo CD v3.6.1) from `https://argoproj.github.io/argo-helm`, release `argocd`, namespace `argocd`: API server and UI, application controller, repo server, ApplicationSet and notifications controllers, Dex and Redis.
- **Reach it:**

    ```bash
    kubectl -n argocd port-forward svc/argocd-server 8080:443
    ```

    Open <https://localhost:8080> (the certificate is self-signed) and sign in as `admin`. Argo CD generates the password on first start:

    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
    ```

    Change the password after the first login and delete that Secret; no password is stored in this repository.
- **Toggle:** `enable_gitops = false` removes Argo CD and its namespace, including the `Application` objects stored in it. Workloads they deployed keep running but are no longer synchronised. Delete applications that carry the `resources-finalizer.argocd.argoproj.io` finalizer beforehand; without the controller nothing clears it and the namespace cannot be removed.
{%- endif %}
{%- if values.enableObservability %}

## Observability: Prometheus, Alertmanager, Grafana, Loki

- **Installed**, all in namespace `monitoring`:
    - chart `kube-prometheus-stack` 93.1.2 from `https://prometheus-community.github.io/helm-charts`, release `kube-prometheus-stack`: Prometheus Operator, one Prometheus (metrics kept for 15 days on a 50 GiB volume), Alertmanager, Grafana (10 GiB volume), node exporter and kube-state-metrics, with the default dashboards and alert rules. The control plane targets a managed cluster does not expose are switched off.
    - chart `loki` 21.1.3 (Loki 3.7.9) from `https://grafana-community.github.io/helm-charts`, release `loki`: a single Loki process that keeps logs for 7 days on a 20 GiB volume.
    - chart `alloy` 1.15.0 (Grafana Alloy v1.21.3) from `https://grafana.github.io/helm-charts`, release `alloy`: a DaemonSet that tails the container logs of every node and sends them to Loki with the labels `namespace`, `pod`, `container`, `app`, `node` and `cluster`.

    Volumes use the storage class the cluster layer provides. Retention and volume sizes are the variables `prometheus_retention`, `prometheus_storage_size`, `loki_retention` and `loki_storage_size`.
- **Reach it:**

    ```bash
    kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
    ```

    Open <http://localhost:3000> and sign in as `admin`. The chart generates the password:

    ```bash
    kubectl -n monitoring get secret kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d
    ```

    Grafana has the data sources Prometheus, Alertmanager and Loki. Logs are under **Explore**, data source **Loki**, for example the query `{namespace="kube-system"}`.

    ```bash
    kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
    kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093
    kubectl -n monitoring port-forward svc/loki 3100:3100
    ```

- **Metrics of the other components:** Prometheus picks up every `ServiceMonitor`, `PodMonitor` and `PrometheusRule` in the cluster, so applications only need to create one. The platform components that are switched on are scraped as well.
- **Alerts** are evaluated but not sent anywhere: add receivers (Slack, e-mail, PagerDuty) with an `AlertmanagerConfig` object or the chart value `alertmanager.config`.
- **Toggle:** `enable_observability = false` removes the three releases and the namespace, and the other components stop creating `ServiceMonitor` objects. The volume claims are deleted with the namespace, so the stored metrics, logs and Grafana changes are lost.
{%- endif %}
{%- if values.enableServiceMesh %}

## Service mesh: Istio

- **Installed:** charts `base` and `istiod` 1.30.8 from `https://istio-release.storage.googleapis.com/charts`, releases `istio-base` and `istiod`, namespace `istio-system`. The base chart (custom resource definitions) is installed first, then the control plane. No Istio gateway is installed; traffic enters through the ingress controller.
- **Use it:** label a namespace and restart its workloads; every pod then gets an Envoy sidecar and mutual TLS between meshed pods.

    ```bash
    kubectl label namespace <namespace> istio-injection=enabled
    kubectl -n <namespace> rollout restart deployment
    kubectl -n istio-system get pods
    ```

    The sidecar's init container needs the `NET_ADMIN` and `NET_RAW` capabilities, which the `baseline` and `restricted` Pod Security Standards refuse. A meshed namespace therefore has to be labelled `pod-security.kubernetes.io/enforce=privileged`.
- **Toggle:** `enable_service_mesh = false` removes istiod and the namespace; the Istio custom resource definitions stay. Remove the `istio-injection` label and restart the workloads first, so that no pod keeps a sidecar without a control plane.
{%- endif %}
{%- if values.enableCertManager %}

## Certificates: cert-manager

- **Installed:** chart `cert-manager` v1.21.3 from `https://charts.jetstack.io`, release `cert-manager`, namespace `cert-manager`: controller, webhook and CA injector, with the custom resource definitions installed by the chart.
- **Use it:** no issuer is created, because an issuer needs an e-mail address or a CA of your organisation. A Let's Encrypt issuer that answers HTTP-01 challenges through the ingress controller:

    ```yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: platform@example.com
        privateKeySecretRef:
          name: letsencrypt-account-key
        solvers:
          - http01:
              ingress:
                ingressClassName: ${{ values.enableIngress if values.enableIngress != 'none' else '<ingress class>' }}
    ```

    An Ingress then asks for a certificate with the annotation `cert-manager.io/cluster-issuer: letsencrypt` and a `tls` section.

    ```bash
    kubectl get clusterissuers,certificates -A
    ```

- **Toggle:** `enable_cert_manager = false` removes the release and the namespace. The custom resource definitions, and with them existing `Certificate` objects and their Secrets, are kept on purpose; certificates are no longer renewed.
{%- endif %}
{%- if values.enableExternalDns %}

## DNS records: external-dns

- **Installed:** chart `external-dns` 1.23.0 from `https://kubernetes-sigs.github.io/external-dns`, release `external-dns`, namespace `external-dns`. It runs as the service account `external-dns`, which the cluster layer binds to a cloud identity that may change DNS records (see the [Overview](index.md)).
- **Use it:** give an Ingress a host name, or a LoadBalancer Service the annotation `external-dns.alpha.kubernetes.io/hostname`, in a DNS zone the identity can change. Records are created and updated, never deleted (`upsert-only`), and are marked with a TXT record that names this cluster as owner.

    ```bash
    kubectl -n external-dns logs deployment/external-dns
    ```

    Limit the zones with the variable `dns_domain_filters`, for example `dns_domain_filters = ["example.com"]`.
- **Toggle:** `enable_external_dns = false` removes the release, the namespace and the cloud identity. Existing DNS records stay.
{%- endif %}
{%- if values.enableIngress == 'nginx' %}

## Ingress controller: ingress-nginx

- **Installed:** chart `ingress-nginx` 4.15.1 (controller 1.15.1) from `https://kubernetes.github.io/ingress-nginx`, release `ingress-nginx`, namespace `ingress`: two controller replicas behind a Service of type LoadBalancer, and the IngressClass `nginx`, which is the default class of the cluster.
- **Reach it:** the address of the cloud load balancer is on the Service. Point DNS at it, or let external-dns do that.

    ```bash
    kubectl -n ingress get service ingress-nginx-controller
    ```

- **Maintenance:** the Kubernetes project retired ingress-nginx in March 2026 and 4.15.1 is its last release, so it receives no more security fixes. For a new platform prefer `ingress_controller = "traefik"`, which serves the same `Ingress` objects; annotations that start with `nginx.ingress.kubernetes.io/` have to be translated.
- **Toggle:** `ingress_controller` is `nginx`, `traefik` or `none`. Changing it replaces the controller and its load balancer, so the public address changes; `none` removes the controller and the namespace `ingress`.
{%- endif %}
{%- if values.enableIngress == 'traefik' %}

## Ingress controller: Traefik

- **Installed:** chart `traefik` 42.3.2 (Traefik v3.7.17) from `https://traefik.github.io/charts`, release `traefik`, namespace `ingress`: two replicas behind a Service of type LoadBalancer (ports 80 and 443), and the IngressClass `traefik`, which is the default class of the cluster. Traefik serves `Ingress` objects and its own `IngressRoute` objects.
- **Reach it:** the address of the cloud load balancer is on the Service. Point DNS at it, or let external-dns do that.

    ```bash
    kubectl -n ingress get service traefik
    ```

- **Toggle:** `ingress_controller` is `nginx`, `traefik` or `none`. Changing it replaces the controller and its load balancer, so the public address changes; `none` removes the controller and the namespace `ingress`.
{%- endif %}
{%- if values.enableOPA %}

## Admission policies: OPA Gatekeeper

- **Installed:** chart `gatekeeper` 3.23.1 from `https://open-policy-agent.github.io/gatekeeper/charts`, release `gatekeeper`, namespace `gatekeeper-system`: three webhook replicas and the audit controller.
- **Use it:** Gatekeeper enforces nothing until policies are added. A policy is a `ConstraintTemplate` (the rule, in Rego or CEL) plus a constraint (where the rule applies); the [Gatekeeper library](https://open-policy-agent.github.io/gatekeeper-library/website/) has ready-made ones. Start a constraint with `enforcementAction: dryrun` and read the audit results before denying requests.

    ```bash
    kubectl get constrainttemplates
    kubectl get constraints
    kubectl -n gatekeeper-system get pods
    ```

    The webhook does not block requests while Gatekeeper is unavailable (failure policy `Ignore`), and it skips the namespace `gatekeeper-system` itself.
- **Toggle:** `enable_opa = false` removes Gatekeeper and its namespace; its custom resource definitions and the policies stored in them stay in the cluster but are no longer enforced.
{%- endif %}
{%- if values.enableVaultIntegration %}

## Secrets from Vault: Vault Secrets Operator

- **Installed:** chart `vault-secrets-operator` 1.6.2 from `https://helm.releases.hashicorp.com`, release `vault-secrets-operator`, namespace `vault`, with a default `VaultConnection` and a default `VaultAuth` object. The operator copies secrets from Vault into Kubernetes Secrets and keeps them up to date. Vault itself is not installed.
- **Configure it:** set the address of your Vault server in `terraform.tfvars`:

    ```hcl
    vault_address = "https://vault.example.com:8200"
    ```

    Without that line the operator looks for a Vault server inside the cluster at `http://vault.vault.svc.cluster.local:8200`. In Vault, enable the Kubernetes auth method for this cluster at the mount `kubernetes` (variable `vault_kubernetes_auth_mount`) and create the role `vault-secrets-operator` (variable `vault_kubernetes_auth_role`), bound to the service accounts that may read secrets and to a policy.
- **Use it:** a workload namespace declares which secret it wants; the default connection and auth method are used when none is named.

    ```yaml
    apiVersion: secrets.hashicorp.com/v1beta1
    kind: VaultStaticSecret
    metadata:
      name: app-config
      namespace: my-app
    spec:
      mount: secret
      type: kv-v2
      path: my-app/config
      refreshAfter: 60s
      destination:
        name: app-config
        create: true
    ```

    ```bash
    kubectl -n vault get vaultconnection,vaultauth
    kubectl -n my-app describe vaultstaticsecret app-config
    ```

- **Toggle:** `enable_vault_integration = false` removes the operator and its namespace. Secrets it already created stay but are no longer refreshed.
{%- endif %}

## Pod Security Standards

`enable_pod_security_standards` is **${{ 'on' if values.enablePodSecurityPolicies else 'off' }}**. When on, every namespace above carries the labels `pod-security.kubernetes.io/enforce`, `audit` and `warn` with the strictest level its component runs under, and the API server rejects pods that ask for more:

| Namespace           | Level        | Why                                                                                         |
| ------------------- | ------------ | ------------------------------------------------------------------------------------------- |
| `argocd`            | `restricted` |                                                                                             |
| `monitoring`        | `privileged` | The node exporter uses the host network and file systems; Alloy reads `/var/log` of the node |
| `istio-system`      | `restricted` |                                                                                             |
| `cert-manager`      | `restricted` |                                                                                             |
| `external-dns`      | `restricted` |                                                                                             |
| `ingress`           | `restricted` |                                                                                             |
| `gatekeeper-system` | `restricted` |                                                                                             |
| `vault`             | `restricted` |                                                                                             |

When off, the namespaces have no such labels and the cluster's default (no enforcement) applies. Namespaces of your own applications are not created by this stack; label them the same way, `restricted` unless a workload needs more.

## Network policies

`enable_network_policies` is **${{ 'on' if values.enableNetworkPolicies else 'off' }}**. When on, the cluster layer switches on NetworkPolicy enforcement and every namespace above gets:

- `default-deny-ingress`: no pod accepts connections unless another policy allows them;
- `allow-same-namespace`: the pods of one component reach each other;
- `allow-prometheus-scrape`: Prometheus reaches the metrics endpoints (only with observability on);
- the rules the component needs from outside its namespace:

| Policy                               | Namespace           | Opens                                                                 |
| ------------------------------------ | ------------------- | --------------------------------------------------------------------- |
| `allow-ingress-nginx-traffic`        | `ingress`           | HTTP, HTTPS and the admission webhook of ingress-nginx, from anywhere |
| `allow-traefik-traffic`              | `ingress`           | HTTP and HTTPS of Traefik, from anywhere                              |
| `allow-argocd-server-from-ingress`   | `argocd`            | The Argo CD server, from the ingress controller                       |
| `allow-grafana-from-ingress`         | `monitoring`        | Grafana, from the ingress controller                                  |
| `allow-prometheus-operator-webhook`  | `monitoring`        | The operator's admission webhook, called by the API server            |
| `allow-cert-manager-webhook`         | `cert-manager`      | The admission webhook, called by the API server                       |
| `allow-istiod-discovery-and-webhook` | `istio-system`      | Sidecar configuration (15010, 15012) and the injection webhook (15017) |
| `allow-gatekeeper-webhook`           | `gatekeeper-system` | The admission webhook, called by the API server                       |

Outgoing connections are not restricted, and `kubectl port-forward` keeps working because it does not pass through the pod network. Namespaces of your own applications get no policy from this stack. `terraform output platform_network_policies` lists the policies and says whether the cluster enforces them.

## All components and their charts

The chart versions are pinned in `platform.tf` (`local.platform_chart_versions`). To upgrade a component, change its version there, read the chart's upgrade notes, and let the pipeline plan and apply the change.

| Setting                         | Chart (repository)                                                      | Version           | Namespace           |
| ------------------------------- | ----------------------------------------------------------------------- | ----------------- | ------------------- |
| `enable_gitops`                 | `argo-cd` (`https://argoproj.github.io/argo-helm`)                      | 10.17.1           | `argocd`            |
| `enable_observability`          | `kube-prometheus-stack` (`https://prometheus-community.github.io/helm-charts`) | 93.1.2     | `monitoring`        |
| `enable_observability`          | `loki` (`https://grafana-community.github.io/helm-charts`)              | 21.1.3            | `monitoring`        |
| `enable_observability`          | `alloy` (`https://grafana.github.io/helm-charts`)                       | 1.15.0            | `monitoring`        |
| `enable_service_mesh`           | `base`, `istiod` (`https://istio-release.storage.googleapis.com/charts`) | 1.30.8           | `istio-system`      |
| `enable_cert_manager`           | `cert-manager` (`https://charts.jetstack.io`)                           | v1.21.3           | `cert-manager`      |
| `enable_external_dns`           | `external-dns` (`https://kubernetes-sigs.github.io/external-dns`)       | 1.23.0            | `external-dns`      |
| `ingress_controller = "nginx"`  | `ingress-nginx` (`https://kubernetes.github.io/ingress-nginx`)          | 4.15.1            | `ingress`           |
| `ingress_controller = "traefik"` | `traefik` (`https://traefik.github.io/charts`)                         | 42.3.2            | `ingress`           |
| `enable_opa`                    | `gatekeeper` (`https://open-policy-agent.github.io/gatekeeper/charts`)  | 3.23.1            | `gatekeeper-system` |
| `enable_vault_integration`      | `vault-secrets-operator` (`https://helm.releases.hashicorp.com`)        | 1.6.2             | `vault`             |

Settings without a form field, set in `terraform.tfvars` when the default does not fit:

| Variable                      | Default                                     | Meaning                                                    |
| ----------------------------- | ------------------------------------------- | ---------------------------------------------------------- |
| `dns_domain_filters`          | `[]`                                        | DNS zones external-dns may manage; empty means every zone its identity can change |
| `vault_address`               | `http://vault.vault.svc.cluster.local:8200` | Vault server of the Vault Secrets Operator                 |
| `vault_kubernetes_auth_mount` | `kubernetes`                                | Mount of the Kubernetes auth method in Vault               |
| `vault_kubernetes_auth_role`  | `vault-secrets-operator`                    | Vault role of the default `VaultAuth` object               |
| `prometheus_retention`        | `15d`                                       | How long Prometheus keeps metrics                          |
| `prometheus_storage_size`     | `50Gi`                                      | Volume of Prometheus                                       |
| `loki_retention`              | `168h`                                      | How long Loki keeps logs                                   |
| `loki_storage_size`           | `20Gi`                                      | Volume of Loki                                             |

On a cluster whose control plane reaches the nodes through a firewall (a private GKE cluster, for example), the admission webhooks listen on these pod ports: cert-manager and the Prometheus Operator 10250, ingress-nginx and Gatekeeper 8443, istiod 15017.
