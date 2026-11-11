# Kubernetes Operator (Go, Kubebuilder)

Creates a repository with a Kubernetes operator written in Go, in the layout
Kubebuilder 4 generates, with one custom resource and a working controller.

## What you get

| Path                        | Content                                                                                                                         |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `api/<version>/`            | The custom resource types with validation markers and generated deep-copy code                                                  |
| `internal/controller/`      | The controller and its envtest suite                                                                                            |
| `cmd/main.go`               | The manager: leader election, health probes, authenticated metrics over HTTPS                                                   |
| `config/`                   | Kustomize manifests: CRD, RBAC, manager Deployment, network policy, ServiceMonitor, samples                                     |
| `test/e2e/`                 | End-to-end tests that deploy the operator to a kind cluster                                                                     |
| `Makefile`                  | `make test`, `make lint`, `make test-e2e`, `make deploy` and the code generators, with pinned tool versions                     |
| `.github/workflows/ci.yaml` | Lint, unit tests, end-to-end tests, and an image published to the GitHub Container Registry with a build provenance attestation |

The controller is a complete example rather than an empty stub: the custom
resource describes an image, a replica count and an optional port, and the
controller reconciles it into a hardened Deployment and a Service that it owns,
and reports `Available`, `Progressing` and `Degraded` conditions. Replace the
fields and the reconcile logic with your own; the tests, RBAC markers and
manifests show where each piece goes.

## Parameters

| Parameter            | Meaning                                                                                                                                |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Operator Name        | Repository, catalog entry and prefix of the cluster objects (`<name>-system` namespace, `<name>-controller-manager` Deployment)        |
| API Domain           | A domain your organisation owns. The API group is `<group>.<domain>`                                                                   |
| API Group            | First label of the API group                                                                                                           |
| API Version          | `v1alpha1`, `v1beta1` or `v1`                                                                                                          |
| Kind                 | The custom resource kind in PascalCase                                                                                                 |
| Plural Resource Name | Optional. Defaults to the lowercase kind followed by `s`; set it for kinds with an irregular plural, for example `proxies` for `Proxy` |

## After creation

1. Clone the repository and run `make test`. It downloads the pinned tools
   into `bin/` and runs the controller against a local API server.
2. Change the types in `api/`, then run `make manifests generate` and commit
   the regenerated files.
3. Pushes to `main` publish `ghcr.io/<owner>/<repository>` with a build
   provenance attestation. Deploy it with
   `make deploy IMG=ghcr.io/<owner>/<repository>@<digest>`.

The repository stays compatible with the Kubebuilder CLI: `kubebuilder create
api` and `kubebuilder create webhook` add further resources to it.
