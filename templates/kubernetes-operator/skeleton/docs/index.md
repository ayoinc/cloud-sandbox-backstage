# ${{ values.name }}

${{ values.description }}

## Overview

`${{ values.name }}` is a Kubernetes operator. It watches `${{ values.kind }}` resources
(`${{ values.group }}.${{ values.domain }}/${{ values.version }}`) in every namespace and keeps a
Deployment, and optionally a Service, in line with each of them.

| | |
| --- | --- |
| Custom resource | `${{ values.kind }}` (`kubectl get ${{ values.plural }}`) |
| Namespace of the operator | `${{ values.name }}-system` |
| Image | `ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}` |

## Reconciliation

1. Read the `${{ values.kind }}`. If it is gone, stop: its Deployment and Service are
   removed by the garbage collector through their owner reference.
2. Create or update the Deployment: `spec.image`, `spec.replicas`,
   `spec.resources`, and the container port when `spec.port` is set.
3. Create or update the Service when `spec.port` is set; delete it when the
   port is removed.
4. Write the status: `observedGeneration`, `readyReplicas` and the conditions.

The controller also watches the Deployments and Services it owns, so a manual
change to either is reverted and a change in ready replicas updates the status.

## Status conditions

| Condition | True when |
| --- | --- |
| `Available` | Every desired replica is updated and ready |
| `Progressing` | The Deployment is still rolling out |
| `Degraded` | The last reconciliation failed; the message holds the error |

Wait for a resource in scripts with:

```sh
kubectl wait ${{ values.plural }}/<name> --for=condition=Available --timeout=2m
```

## Operating

- **Logs**: `kubectl logs -n ${{ values.name }}-system deploy/${{ values.name }}-controller-manager`
- **Events**: the controller records an event on the `${{ values.kind }}` whenever it creates or
  changes an object, and a warning when reconciliation fails.
- **Metrics**: controller-runtime metrics (`controller_runtime_reconcile_total`,
  `controller_runtime_reconcile_errors_total`, work queue depth) on port 8443
  of the `${{ values.name }}-controller-manager-metrics-service` Service, over HTTPS with
  token authentication. `config/prometheus/` holds a ServiceMonitor.
- **Availability**: leader election is enabled in the manager Deployment, so more
  than one replica can run; one is active at a time.

## Testing

| Level | Command | What runs |
| --- | --- | --- |
| Controller | `make test` | Ginkgo suite against a local API server and etcd (envtest) |
| End to end | `make test-e2e` | The built image on a kind cluster: manager start-up, metrics, the sample resource |

See the `README.md` of the repository for development and deployment commands.
