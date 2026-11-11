# ${{ values.name }}

${{ values.description }}

A Kubernetes operator written in Go with [Kubebuilder](https://book.kubebuilder.io/)
and [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime).
It serves the `${{ values.kind }}` custom resource of the API group
`${{ values.group }}.${{ values.domain }}/${{ values.version }}`.

## What the controller does

A `${{ values.kind }}` describes an image, a replica count and an optional port:

```yaml
apiVersion: ${{ values.group }}.${{ values.domain }}/${{ values.version }}
kind: ${{ values.kind }}
metadata:
  name: ${{ values.kind_lower }}-sample
spec:
  image: registry.k8s.io/pause:3.10
  replicas: 2
```

The controller reconciles it into a Deployment with a restricted security
context and, when `spec.port` is set, a ClusterIP Service. Both are owned by the
`${{ values.kind }}`, so deleting it removes them. The status carries
`readyReplicas`, `observedGeneration` and the conditions `Available`,
`Progressing` and `Degraded`.

## Requirements

- Go (the version in `go.mod`), Docker, `kubectl` and `make`
- [kind](https://kind.sigs.k8s.io/) for the end-to-end tests

Every other tool (controller-gen, kustomize, setup-envtest, golangci-lint) is
downloaded into `bin/` by the Makefile at a pinned version.

## Development

```sh
make test          # generate code and manifests, then run the envtest suite
make lint          # golangci-lint
make run           # run the controller on your machine against the current kubeconfig
make test-e2e      # build the image, deploy to a kind cluster and run test/e2e
make help          # every target
```

After changing `api/${{ values.version }}/${{ values.kind_lower }}_types.go` or an RBAC
marker in the controller, run `make manifests generate` and commit the result.
CI fails when the generated files are out of date.

## Layout

| Path | Content |
| --- | --- |
| `api/${{ values.version }}/` | Types of the custom resource and generated deep-copy code |
| `internal/controller/` | The reconciler and its envtest suite |
| `cmd/main.go` | Manager set-up: leader election, probes, authenticated metrics |
| `config/crd/` | Generated CustomResourceDefinition |
| `config/rbac/` | Generated manager role, plus admin, editor and viewer roles for the resource |
| `config/manager/` | Deployment of the controller manager |
| `config/default/` | Kustomization that assembles the installation in the `${{ values.name }}-system` namespace |
| `config/samples/` | A sample `${{ values.kind }}` |
| `test/e2e/` | End-to-end suite |

## Deploying

Pushes to `main` publish `ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}`
with a build provenance attestation. Deploy an image by digest:

```sh
make deploy IMG=ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}@sha256:<digest>
kubectl apply -k config/samples
kubectl get ${{ values.plural }}
```

`make build-installer IMG=<image>` writes the whole installation to
`dist/install.yaml` for delivery through GitOps. `make undeploy` and
`make uninstall` remove the controller and the CRD.

Verify the provenance of an image before deploying it:

```sh
gh attestation verify oci://ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}@sha256:<digest> \
  --repo ${{ values.destination.owner }}/${{ values.destination.repo }}
```

## Security defaults

- The manager runs as non-root with a read-only root filesystem, no
  capabilities and the `RuntimeDefault` seccomp profile; its namespace can
  enforce the `restricted` Pod Security Standard.
- The manager's ClusterRole is generated from the `+kubebuilder:rbac` markers
  and contains only what the controller uses.
- Metrics are served over HTTPS and require a token authorised for the
  `/metrics` path.
- `config/network-policy/` restricts access to the metrics endpoint; enable it
  in `config/default/kustomization.yaml`.

## Extending

The project file `PROJECT` keeps the repository compatible with the Kubebuilder
CLI:

```sh
kubebuilder create api --group ${{ values.group }} --version ${{ values.version }} --kind AnotherKind
kubebuilder create webhook --group ${{ values.group }} --version ${{ values.version }} --kind ${{ values.kind }} --defaulting --programmatic-validation
```
