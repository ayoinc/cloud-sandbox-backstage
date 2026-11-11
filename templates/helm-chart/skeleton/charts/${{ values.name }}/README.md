# ${{ values.name }}

${{ values.description }}

## Install

```sh
helm install my-release oci://ghcr.io/${{ values.destination.owner | lower }}/charts/${{ values.name }} --version 0.1.0
```

## Values

Values are validated against `values.schema.json`: an unknown key or a value
of the wrong type fails the install with a message that names it.

| Key | Default | Description |
| --- | --- | --- |
| `replicaCount` | `1` | Number of pods. Ignored when `autoscaling.enabled` |
| `image.repository` | `${{ values.image_repository }}` | Image repository |
| `image.tag` | chart `appVersion` | Image tag |
| `image.digest` | `""` | Image digest (`sha256:...`); takes precedence over the tag |
| `image.pullPolicy` | `IfNotPresent` | |
| `imagePullSecrets` | `[]` | Secrets with registry credentials |
| `nameOverride`, `fullnameOverride` | `""` | Override the generated names |
| `containerPort` | `${{ values.container_port }}` | Port the application listens on |
| `command`, `args` | `[]` | Override the image's entrypoint and arguments |
| `env`, `envFrom` | `[]` | Environment variables of the container |
| `serviceAccount.create` | `true` | Create a ServiceAccount |
| `serviceAccount.automount` | `false` | Mount the ServiceAccount token |
| `serviceAccount.annotations` | `{}` | For example a workload identity annotation |
| `serviceAccount.name` | release full name | |
| `podAnnotations`, `podLabels` | `{}` | |
| `podSecurityContext` | non-root, `RuntimeDefault` seccomp | Pod security context |
| `securityContext` | no privilege escalation, read-only root, no capabilities | Container security context |
| `service.type` | `ClusterIP` | |
| `service.port` | `80` | |
| `ingress.enabled` | `false` | Expose the Service through an Ingress |
| `ingress.className`, `ingress.annotations` | | |
| `ingress.hosts` | `[]` | `[{host, paths: [{path, pathType}]}]`; required when the ingress is enabled |
| `ingress.tls` | `[]` | `[{secretName, hosts}]` |
| `resources` | 100m CPU and 128Mi requested, 256Mi memory limit | |
| `livenessProbe`, `readinessProbe` | HTTP GET `/` on the container port | |
| `startupProbe` | `{}` | |
| `autoscaling.enabled` | `false` | Create a HorizontalPodAutoscaler |
| `autoscaling.minReplicas`, `maxReplicas` | `2`, `10` | |
| `autoscaling.targetCPUUtilizationPercentage` | `75` | |
| `autoscaling.targetMemoryUtilizationPercentage` | none | |
| `podDisruptionBudget.enabled` | `false` | Enable with more than one replica |
| `podDisruptionBudget.maxUnavailable` | `1` | |
| `networkPolicy.enabled` | `true` | Only allow traffic to the container port |
| `networkPolicy.ingressFrom` | `[]` | Allowed peers; empty allows every pod in the cluster |
| `extraVolumes`, `extraVolumeMounts` | `[]` | For example an `emptyDir` for `/tmp` |
| `nodeSelector`, `tolerations`, `affinity`, `topologySpreadConstraints` | | Scheduling |

## Examples

A writable `/tmp` with the read-only root filesystem:

```yaml
extraVolumes:
  - name: tmp
    emptyDir: {}
extraVolumeMounts:
  - name: tmp
    mountPath: /tmp
```

Three replicas spread over nodes, kept available during maintenance:

```yaml
replicaCount: 3
podDisruptionBudget:
  enabled: true
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: ${{ values.name }}
```
