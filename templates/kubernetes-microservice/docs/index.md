# Kubernetes Microservice Template

Creates a containerised microservice with Kubernetes manifests in a new GitHub
repository. The pipeline lints, tests, validates the manifests, deploys the
image to a throwaway kind cluster and publishes it; it passes on the first
push.

## Form

| Field                     | Effect                                                                                                                                         |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Service Name              | Name of the service, the Kubernetes resources and the catalog entry                                                                            |
| Description               | Catalog entry, OpenAPI description, documentation                                                                                              |
| Owner                     | Owner of the catalog entries                                                                                                                   |
| Programming Language      | Starter service, its tests and its Dockerfile: Node.js, Python, Java, Go or .NET                                                               |
| Database Type             | `DATABASE_URL` from the Secret `<name>-secrets`, the database port in the NetworkPolicy, a catalog Resource                                    |
| Message Queue             | `MESSAGE_QUEUE_URL` from the same Secret, the broker port in the NetworkPolicy, a catalog Resource                                             |
| Cloud Provider            | Ingress class and annotations; how `deploy.yaml` signs in to the cluster (EKS, AKS, GKE, or a kubeconfig)                                      |
| Environment Strategy      | One set of manifests; or a base with dev, staging and production overlays; or one set plus an Argo CD Application and no deployment workflow   |
| Kubernetes Namespace      | Namespace of the resources; with the multi-environment strategy a prefix for `-dev`, `-staging` and `-production`                              |
| Deployment Strategy       | Deployment with rolling updates, or an Argo Rollouts Rollout with a blue-green or canary strategy                                              |
| Horizontal Pod Autoscaler | Adds `hpa.yaml` (2 to 10 pods on CPU and memory)                                                                                               |
| Pod Disruption Budget     | Adds `pdb.yaml` (one pod unavailable at most)                                                                                                  |
| Monitoring Stack          | Pod annotations for Prometheus or New Relic scraping, Datadog autodiscovery or Elastic hints; Basic adds none                                  |
| Distributed Tracing       | Pod annotation for OpenTelemetry Operator auto-instrumentation, `OTEL_SERVICE_NAME`, OTLP ports in the NetworkPolicy                           |
| Security Scanning         | Adds `security.yaml`: Trivy reports for manifests, dependencies and image                                                                      |
| Policy Enforcement        | Adds OPA policies with tests and `policy.yaml` (conftest); enforces the restricted Pod Security Standard on the namespace the template creates |
| Integration Testing       | Adds `scripts/kind-test.sh` and `integration.yaml`, which deploy to a kind cluster and call the service                                        |
| Code Quality Analysis     | Adds `sonar-project.properties` and `code-quality.yaml`; the analysis is skipped until `SONAR_TOKEN` is set                                    |
| Repository                | GitHub repository to create                                                                                                                    |

The database and the message broker themselves are not created, and the
starter service does not connect to them: the template wires the settings.

## What is generated

- A starter service on port 8080 with `/`, `/health`, `/ready` and `/metrics`,
  and its unit tests
- `Dockerfile` with a `test` stage that runs the unit tests and a runtime
  stage that runs as a non-root user
- `k8s/`: kustomize manifests (ServiceAccount, ConfigMap, Deployment or
  Rollout, Service, Ingress, NetworkPolicy and the selected options)
- `scripts/`: render, validate and deploy the manifests
- `api-spec.yaml`: OpenAPI description, registered as an API in the catalog
- `.github/workflows/ci.yaml` and the workflows of the selected options
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

## What needs configuration

Nothing for the pipeline to pass. These only do work once they are set up:

| Workflow            | Setting                                                                 |
| ------------------- | ----------------------------------------------------------------------- |
| `deploy.yaml`       | Repository variables for the cloud sign-in, or the `KUBE_CONFIG` secret |
| `code-quality.yaml` | The `SONAR_TOKEN` secret                                                |

Until then each of them runs a short job that reports what is missing and
skips the rest. The generated documentation lists the settings.

Blue-green and canary deployments need the Argo Rollouts controller in the
cluster, tracing needs the OpenTelemetry Operator, and the GitOps strategy
needs Argo CD, where `argocd/application.yaml` is applied once.

## Template layout

| Directory                    | Used                                                 |
| ---------------------------- | ---------------------------------------------------- |
| `skeleton/base`              | Always                                               |
| `skeleton/lang-<language>`   | The selected language                                |
| `skeleton/k8s`               | Always; written to `k8s/` or `k8s/base/`             |
| `skeleton/k8s-namespace`     | Multi-environment, or a namespace other than default |
| `skeleton/k8s-hpa`           | Horizontal Pod Autoscaler                            |
| `skeleton/k8s-pdb`           | Pod Disruption Budget                                |
| `skeleton/k8s-overlays`      | Multi-environment                                    |
| `skeleton/argocd`            | GitOps                                               |
| `skeleton/deploy-<provider>` | Single and multi-environment                         |
| `skeleton/integration-test`  | Integration Testing                                  |
| `skeleton/security`          | Security Scanning                                    |
| `skeleton/policy`            | Policy Enforcement                                   |
| `skeleton/code-quality`      | Code Quality Analysis                                |
