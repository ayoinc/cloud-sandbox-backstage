{%- set multi = values.environment_strategy == 'multi-env' -%}
{%- set gitops = values.environment_strategy == 'gitops' -%}
{%- set rollout = values.deployment_strategy != 'rolling-update' -%}
{%- set k8s = 'k8s/base' if multi else 'k8s' -%}
{%- set has_namespace = multi or values.kubernetes_namespace != 'default' -%}
{%- set needs_secret = values.database_type != 'none' or values.message_queue != 'none' -%}
# ${{ values.name }}

${{ values.description }}

## Overview

| Setting             | Value                                                                               |
| ------------------- | ----------------------------------------------------------------------------------- |
| Service             | `${{ values.name }}`                                                                |
| Owner               | `${{ values.owner }}`                                                               |
| Language            | {% if values.language == 'nodejs' %}Node.js 24{% elif values.language == 'python' %}Python 3.13{% elif values.language == 'java' %}Java 21{% elif values.language == 'golang' %}Go 1.27{% else %}.NET 10{% endif %} |
| Namespace           | {% if multi %}`${{ values.kubernetes_namespace }}-dev`, `${{ values.kubernetes_namespace }}-staging`, `${{ values.kubernetes_namespace }}-production`{% else %}`${{ values.kubernetes_namespace }}`{% endif %} |
| Environments        | {% if multi %}dev, staging, production (kustomize overlays){% elif gitops %}One, synced by Argo CD{% else %}One{% endif %} |
| Workload            | {% if rollout %}Argo Rollouts `Rollout` (${{ values.deployment_strategy }}){% else %}`Deployment` (rolling update){% endif %} |
| Cloud provider      | ${{ values.cloud_provider }}                                                        |
| Database            | ${{ values.database_type }}                                                         |
| Message queue       | ${{ values.message_queue }}                                                         |
| Monitoring          | ${{ values.monitoring_stack }}                                                      |
| Repository          | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

```d2
direction: right

push: Push to main {
  shape: oval
}

ci: CI {
  lint: "Lint\nHadolint, kubeconform"
  image: "Image\nunit tests, build, probes"
  lint -> image
}

registry: ghcr.io {
  shape: cylinder
}

cluster: Kubernetes {
  ingress: Ingress
  service: Service
  workload: "${{ 'Rollout' if rollout else 'Deployment' }}\n${{ values.name }}"
  ingress -> service -> workload
}

push -> ci.lint
ci.image -> registry: publish
{%- if gitops %}
argocd: Argo CD
argocd -> cluster: syncs k8s/
{%- else %}
deploy: Deploy workflow
ci.image -> deploy: after success
deploy -> cluster: scripts/deploy.sh
{%- endif %}
registry -> cluster.workload: pull
```

## Project structure

```
${{ values.name }}/
├── .github/workflows/
│   ├── ci.yaml                # Lint, unit tests, image build and publish
{%- if not gitops %}
│   ├── deploy.yaml            # Deployment to the cluster (${{ values.cloud_provider }})
{%- endif %}
{%- if values.enable_automated_testing %}
│   ├── integration.yaml       # Deployment to a throwaway kind cluster
{%- endif %}
{%- if values.enable_security_scanning %}
│   ├── security.yaml          # Trivy scans
{%- endif %}
{%- if values.enable_policy_enforcement %}
│   ├── policy.yaml            # Policy check of the manifests
{%- endif %}
{%- if values.enable_code_quality %}
│   └── code-quality.yaml      # SonarQube analysis
{%- endif %}
{%- if values.language == 'nodejs' %}
├── src/                       # The service (index.js, server.js)
├── test/                      # Unit tests (node --test)
├── package.json
├── package-lock.json
{%- elif values.language == 'python' %}
├── app.py                     # The service
├── test_app.py                # Unit tests (unittest)
├── requirements.txt
{%- elif values.language == 'java' %}
├── src/main/java/app/         # The service (Main.java)
├── src/test/java/app/         # Unit tests (MainTest.java)
{%- elif values.language == 'golang' %}
├── main.go                    # The service
├── main_test.go               # Unit tests (go test)
├── go.mod
{%- else %}
├── src/App/                   # The service (Program.cs)
├── tests/App.Tests/           # Unit tests (xUnit)
{%- endif %}
├── Dockerfile                 # Build, test and runtime stages
{%- if multi %}
├── k8s/
│   ├── base/                  # Manifests shared by all environments
│   └── overlays/              # dev, staging, production
{%- else %}
├── k8s/                       # Kubernetes manifests (kustomize)
{%- endif %}
{%- if gitops %}
├── argocd/application.yaml    # Argo CD Application for k8s/
{%- endif %}
{%- if values.enable_policy_enforcement %}
├── policy/                    # OPA policies for the manifests, with tests
{%- endif %}
├── scripts/
│   ├── render-manifests.sh    # Prints the manifests of an environment
│   ├── validate-manifests.sh  # kubeconform validation
{%- if values.enable_policy_enforcement %}
│   ├── check-policies.sh      # conftest policy check
{%- endif %}
{%- if values.enable_automated_testing %}
│   ├── kind-test.sh           # Deploys to a throwaway kind cluster
{%- endif %}
│   └── deploy.sh              # Applies the manifests with a given image
├── api-spec.yaml              # OpenAPI description of the endpoints
{%- if values.enable_code_quality %}
├── sonar-project.properties
{%- endif %}
├── catalog-info.yaml          # Backstage catalog entry
└── mkdocs.yml                 # TechDocs configuration
```

## The service

A starter service without dependencies outside the standard library{% if values.language == 'dotnet' %} of ASP.NET Core{% endif %}. It listens on the port in `PORT` (default `8080`).

| Method | Path       | Response                                                            |
| ------ | ---------- | ------------------------------------------------------------------- |
| GET    | `/`        | `{ "service": "${{ values.name }}", "environment": "..." }`         |
| GET    | `/health`  | `{ "status": "healthy" }`, used by the liveness and startup probes  |
| GET    | `/ready`   | `{ "status": "ready" }`, used by the readiness probe                |
| GET    | `/metrics` | `http_requests_total` in the Prometheus text format                 |
| other  | any        | `404` with `{ "error": "Not Found" }`                               |

`environment` is the value of the `ENVIRONMENT` variable, which the ConfigMap
sets; outside the cluster it is `local`. `api-spec.yaml` describes the
endpoints in OpenAPI 3.

The `Dockerfile` has a build stage, a `test` stage that runs the unit tests,
and a runtime stage that runs as the non-root user `10001`.

```bash
docker build --target test .                 # unit tests
docker build -t ${{ values.name }}:local .   # image
docker run --rm -p 8080:8080 ${{ values.name }}:local
```

## Kubernetes manifests

The manifests are a kustomize directory, `${{ k8s }}/`:

| File                  | Resource                                                                         |
| --------------------- | -------------------------------------------------------------------------------- |
{%- if has_namespace %}
| `namespace.yaml`      | Namespace{% if values.enable_policy_enforcement %} with the restricted Pod Security Standard enforced{% endif %} |
{%- endif %}
| `serviceaccount.yaml` | ServiceAccount without an API token                                              |
| `configmap.yaml`      | ConfigMap `${{ values.name }}-config`, loaded as environment variables           |
| `workload.yaml`       | {% if rollout %}Rollout (${{ values.deployment_strategy }}){% else %}Deployment (rolling update){% endif %}: probes, resource limits, read-only root filesystem, non-root |
| `service.yaml`        | ClusterIP Service on port 80{% if values.deployment_strategy == 'blue-green' %}, and the preview Service{% endif %} |
| `ingress.yaml`        | Ingress for `${{ values.name }}.example.com`                                     |
| `networkpolicy.yaml`  | Allows the HTTP port in; DNS, HTTPS and the configured dependencies out          |
{%- if values.enable_hpa %}
| `hpa.yaml`            | HorizontalPodAutoscaler, 2 to 10 pods on CPU and memory                          |
{%- endif %}
{%- if values.enable_pdb %}
| `pdb.yaml`            | PodDisruptionBudget, one pod unavailable at most                                 |
{%- endif %}

```bash
bash scripts/render-manifests.sh{% if multi %} staging{% endif %}     # print the manifests
bash scripts/validate-manifests.sh   # kubeconform, every environment
```

Things to adapt before the first real deployment:

- **Host name.** Replace `${{ values.name }}.example.com` in `${{ k8s }}/ingress.yaml`{% if multi %} and in the overlays{% endif %}.
- **Ingress class.** {% if values.cloud_provider == 'aws' %}The Ingress uses the `alb` class of the AWS Load Balancer Controller and creates an internal Application Load Balancer.{% elif values.cloud_provider == 'azure' %}The Ingress uses the class of the AKS application routing add-on.{% elif values.cloud_provider == 'gcp' %}The Ingress uses the GKE Ingress controller (`gce`), and the Service is annotated for container-native load balancing.{% else %}The Ingress uses the `nginx` class.{% endif %}
- **Image pull.** Packages on ghcr.io are private by default. Make the package public or add an image pull secret to the ServiceAccount.
{%- if rollout %}
- **Argo Rollouts.** The cluster needs the [Argo Rollouts controller](https://argo-rollouts.readthedocs.io/en/stable/installation/).
{%- endif %}
{%- if multi %}

### Environments

`k8s/overlays/<environment>` adjusts the base for each environment:

| Environment | Namespace                                       | Host                                     |
| ----------- | ----------------------------------------------- | ---------------------------------------- |
| dev         | `${{ values.kubernetes_namespace }}-dev`        | `${{ values.name }}-dev.example.com`     |
| staging     | `${{ values.kubernetes_namespace }}-staging`    | `${{ values.name }}-staging.example.com` |
| production  | `${{ values.kubernetes_namespace }}-production` | `${{ values.name }}.example.com`         |

Each overlay also sets `ENVIRONMENT` and the number of pods.
{%- endif %}
{%- if needs_secret %}

### Connection strings

The pods read {% if values.database_type != 'none' %}`DATABASE_URL`{% endif %}{% if values.database_type != 'none' and values.message_queue != 'none' %} and {% endif %}{% if values.message_queue != 'none' %}`MESSAGE_QUEUE_URL`{% endif %} from the Secret
`${{ values.name }}-secrets`. The Secret is not kept in the repository; create
it in each namespace before the first deployment:

```bash
kubectl --namespace <namespace> create secret generic ${{ values.name }}-secrets \
{%- if values.database_type != 'none' %}
  --from-literal=database-url='<connection string>'{% if values.message_queue != 'none' %} \{% endif %}
{%- endif %}
{%- if values.message_queue != 'none' %}
  --from-literal=message-queue-url='<connection string>'
{%- endif %}
```

The starter service does not open these connections yet. The NetworkPolicy
already allows the pods to reach {% if values.database_type != 'none' %}the ${{ values.database_type }} port{% endif %}{% if values.database_type != 'none' and values.message_queue in ['rabbitmq', 'kafka', 'redis-pub-sub'] %} and {% endif %}{% if values.message_queue in ['rabbitmq', 'kafka', 'redis-pub-sub'] %}the ${{ values.message_queue }} port{% endif %}{% if values.message_queue == 'aws-sqs' %}{% if values.database_type != 'none' %} and {% endif %}SQS over HTTPS{% endif %}.
{%- endif %}
{%- if rollout %}

### ${{ 'Blue-green' if values.deployment_strategy == 'blue-green' else 'Canary' }} deployments

{% if values.deployment_strategy == 'blue-green' -%}
A new version starts beside the running one and is reachable through the
Service `${{ values.name }}-preview`. It takes the traffic of the Service
`${{ values.name }}` when it is promoted:
{%- else -%}
A new version first gets 20% of the pods and waits. After promotion it gets
50%, and five minutes later all of them:
{%- endif %}

```bash
kubectl argo rollouts get rollout ${{ values.name }} --namespace <namespace>
kubectl argo rollouts promote ${{ values.name }} --namespace <namespace>
```

`kubectl argo rollouts` is the [Argo Rollouts kubectl plugin](https://argo-rollouts.readthedocs.io/en/stable/installation/#kubectl-plugin-installation).
{%- endif %}

## Observability

{% if values.monitoring_stack == 'basic' -%}
The service exposes `http_requests_total` on `/metrics`. No scraping
annotations are set.
{%- elif values.monitoring_stack == 'datadog' -%}
The service exposes `http_requests_total` on `/metrics`. The pods carry the
Datadog autodiscovery annotation for the OpenMetrics check and the
`tags.datadoghq.com/service` label, so a Datadog Agent in the cluster collects
the metrics.
{%- elif values.monitoring_stack == 'elastic-stack' -%}
The service exposes `http_requests_total` on `/metrics`. The pods carry the
`co.elastic.metrics/*` and `co.elastic.logs/enabled` hints, so Elastic Agent
or Metricbeat with hints-based autodiscover collects metrics and logs.
{%- else -%}
The service exposes `http_requests_total` on `/metrics`. The pods carry the
`prometheus.io/scrape`, `prometheus.io/port` and `prometheus.io/path`
annotations, which {% if values.monitoring_stack == 'new-relic' %}the New Relic Prometheus agent{% else %}a Prometheus with annotation-based discovery{% endif %} uses to scrape them.
{%- endif %}
{%- if values.enable_tracing %}

The pods are annotated for auto-instrumentation by the
[OpenTelemetry Operator](https://opentelemetry.io/docs/platforms/kubernetes/operator/automatic/).
With the operator and an `Instrumentation` resource in the cluster, traces are
exported without code changes; `OTEL_SERVICE_NAME` is set in the ConfigMap and
the NetworkPolicy allows OTLP traffic (ports 4317 and 4318). Without the
operator the annotation has no effect.
{%- endif %}

## Continuous integration

Every workflow runs on pushes and pull requests to `main`.

| Workflow           | What it does                                                                                    |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| `ci.yaml`          | Hadolint, kubeconform, unit tests (`--target test`), image build, start and probe calls, publish |
{%- if values.enable_automated_testing %}
| `integration.yaml` | Creates a kind cluster{% if rollout %}, installs Argo Rollouts{% endif %}, deploys the image with the manifests{% if multi %} of dev{% endif %} and calls the service |
{%- endif %}
{%- if values.enable_security_scanning %}
| `security.yaml`    | Trivy reports: misconfigurations of manifests and Dockerfile, vulnerable dependencies, image     |
{%- endif %}
{%- if values.enable_policy_enforcement %}
| `policy.yaml`      | conftest: unit tests of the policies, then the manifests of every environment against them      |
{%- endif %}
{%- if values.enable_code_quality %}
| `code-quality.yaml` | SonarQube analysis; skipped until the `SONAR_TOKEN` secret exists                              |
{%- endif %}

On pushes to `main`, `ci.yaml` publishes the image to the GitHub Container
Registry with the workflow's own token:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```
{%- if values.enable_security_scanning %}

The Trivy scans report and do not fail the build. In a public repository the
misconfiguration results also appear in the repository's Security tab.
{%- endif %}
{%- if values.enable_policy_enforcement %}

### Policies

`policy/workload.rego` holds the rules: non-root pods, no privilege
escalation, read-only root filesystem, all capabilities dropped, CPU and
memory requests and limits, liveness and readiness probes, no host network,
no LoadBalancer Services. `policy/workload_test.rego` tests them.

```bash
conftest verify --policy policy    # unit tests of the policies
bash scripts/check-policies.sh     # the manifests against the policies
```
{%- if has_namespace %}

The namespace is labelled to enforce the restricted
[Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/),
so Kubernetes itself rejects pods that break it.
{%- endif %}
{%- endif %}
{%- if values.enable_code_quality %}

### SonarQube

Set the repository secret `SONAR_TOKEN` to enable the analysis. For SonarQube
Server also set the repository variable `SONAR_HOST_URL`; without it the
results go to SonarQube Cloud. Project key and organisation are in
`sonar-project.properties`.
{%- endif %}
{%- if values.enable_automated_testing %}

### Integration test

```bash
docker build -t ${{ values.name }}:local .
bash scripts/kind-test.sh ${{ values.name }}:local
```

The script needs Docker, kind, kubectl and curl. It creates the cluster
`${{ values.name }}-test`, deploys with `scripts/deploy.sh`, calls every
endpoint through a port-forward and deletes the cluster.
{%- endif %}

## Deployment

{% if gitops -%}
Argo CD deploys this service. Register the Application once, in the cluster
that runs Argo CD:

```bash
kubectl apply --namespace argocd --filename argocd/application.yaml
```

Argo CD then keeps the cluster in sync with `k8s/` on `main`, creates the
namespace `${{ values.kubernetes_namespace }}` and removes resources that are
deleted from the repository. If the repository is private, add it to Argo CD
first (`argocd repo add`).

To roll out a version, set its image tag in `k8s/kustomization.yaml` and merge
the change:

```yaml
images:
  - name: ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}
    newTag: sha-<commit>
```

`scripts/deploy.sh <image>` applies the same manifests directly, for clusters
without Argo CD.
{%- else -%}
`.github/workflows/deploy.yaml` runs after every successful CI run on `main`
and on demand (**Actions**, **Deploy**, **Run workflow**). It deploys the
image of that commit with `scripts/deploy.sh`{% if multi %}: to `dev` after CI, or to the environment given when it is started by hand{% endif %}.

Until it is configured the workflow only reports that deployment is skipped.
{% if values.cloud_provider == 'aws' -%}
To enable it, create an IAM role that trusts this repository through
[GitHub's OIDC provider](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
and may access the EKS cluster, then set these repository variables:

| Variable           | Value                          |
| ------------------ | ------------------------------ |
| `AWS_ROLE_ARN`     | ARN of the role to assume      |
| `AWS_REGION`       | Region of the cluster          |
| `EKS_CLUSTER_NAME` | Name of the EKS cluster        |
{%- elif values.cloud_provider == 'azure' -%}
To enable it, create an app registration or managed identity with a
[federated credential](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
for this repository and access to the AKS cluster, then set these repository
variables:

| Variable                | Value                              |
| ----------------------- | ---------------------------------- |
| `AZURE_CLIENT_ID`       | Client ID of the identity          |
| `AZURE_TENANT_ID`       | Tenant ID                          |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID                    |
| `AKS_RESOURCE_GROUP`    | Resource group of the AKS cluster  |
| `AKS_CLUSTER_NAME`      | Name of the AKS cluster            |
{%- elif values.cloud_provider == 'gcp' -%}
To enable it, set up
[Workload Identity Federation](https://github.com/google-github-actions/auth#workload-identity-federation-through-a-service-account)
for this repository with a service account that may access the GKE cluster,
then set these repository variables:

| Variable                         | Value                                           |
| -------------------------------- | ----------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full resource name of the identity provider     |
| `GCP_SERVICE_ACCOUNT`            | E-mail address of the service account           |
| `GKE_CLUSTER_NAME`               | Name of the GKE cluster                         |
| `GKE_LOCATION`                   | Region or zone of the cluster                   |
{%- else -%}
To enable it, set the repository secret `KUBE_CONFIG` to a base64-encoded
kubeconfig of a service account that may deploy to the namespace:

```bash
base64 < kubeconfig.yaml | gh secret set KUBE_CONFIG
```

The cluster's API server has to be reachable from the workflow runner; use a
self-hosted runner if it is not.
{%- endif %}

To deploy by hand, point kubectl at the cluster and run:

```bash
bash scripts/deploy.sh ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>{% if multi %} staging{% endif %}
```
{%- endif %}

## References

- [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [kubeconform](https://github.com/yannh/kubeconform)
{%- if rollout %}
- [Argo Rollouts](https://argo-rollouts.readthedocs.io/)
{%- endif %}
{%- if gitops %}
- [Argo CD](https://argo-cd.readthedocs.io/)
{%- endif %}
{%- if values.enable_policy_enforcement %}
- [conftest](https://www.conftest.dev/)
{%- endif %}
