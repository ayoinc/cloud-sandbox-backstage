# Overview

## Architecture

The Helm Charts Repository provides a centralized collection of Kubernetes Helm charts for deploying applications and services. Charts follow best practices for security, scalability, and maintainability.

```
+------------------------------------------------------------------+
|                      CHART ARCHITECTURE                           |
+------------------------------------------------------------------+
|                                                                   |
|  +-------------------+         +-------------------+              |
|  |   values.yaml     |         |   Chart.yaml      |              |
|  |   User config     |-------->|   Metadata        |              |
|  |   Overrides       |         |   Dependencies    |              |
|  +-------------------+         +-------------------+              |
|           |                            |                          |
|           v                            v                          |
|  +--------------------------------------------------+            |
|  |              TEMPLATE ENGINE                      |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | _helpers   |  | deployment |  | service    |  |            |
|  |  | .tpl       |  | .yaml      |  | .yaml      |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | ingress    |  | configmap  |  | secret     |  |            |
|  |  | .yaml      |  | .yaml      |  | .yaml      |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                          |                                        |
|                          v                                        |
|  +--------------------------------------------------+            |
|  |           RENDERED KUBERNETES MANIFESTS           |            |
|  +--------------------------------------------------+            |
|                                                                   |
+------------------------------------------------------------------+
```

## Chart Development

### Chart.yaml Structure

```yaml
# Chart.yaml
apiVersion: v2
name: webapp
description: A Helm chart for deploying web applications
type: application
version: 2.5.0
appVersion: "1.0.0"

# Keywords for search
keywords:
  - web
  - http
  - nginx
  - application

# Maintainers
maintainers:
  - name: Platform Team
    email: platform@company.com
    url: https://github.com/company/platform-team

# Source repository
home: https://github.com/company/helm-charts
sources:
  - https://github.com/company/helm-charts

# Chart icon
icon: https://company.com/icons/webapp.png

# Kubernetes version constraint
kubeVersion: ">=1.25.0-0"

# Dependencies
dependencies:
  - name: common
    version: 1.x.x
    repository: "file://../library/common"
  - name: redis
    version: 18.x.x
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
    tags:
      - cache
  - name: postgresql
    version: 14.x.x
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
    alias: db
```

### Values.yaml Best Practices

```yaml
# values.yaml
# -- Number of replicas
replicaCount: 2

# Image configuration
image:
  # -- Container image repository
  repository: company/webapp
  # -- Image pull policy
  pullPolicy: IfNotPresent
  # -- Image tag (defaults to chart appVersion)
  tag: ""

# -- Image pull secrets
imagePullSecrets: []

# -- Override the name
nameOverride: ""
# -- Override the fullname
fullnameOverride: ""

# Service Account
serviceAccount:
  # -- Create service account
  create: true
  # -- Service account annotations
  annotations: {}
  # -- Service account name
  name: ""

# Pod annotations
podAnnotations: {}

# Pod security context
podSecurityContext:
  fsGroup: 1000
  runAsNonRoot: true

# Container security context
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
      - ALL

# Service configuration
service:
  # -- Service type
  type: ClusterIP
  # -- Service port
  port: 80
  # -- Target container port
  targetPort: 8080
  # -- Node port (when type is NodePort)
  nodePort: ""

# Ingress configuration
ingress:
  # -- Enable ingress
  enabled: false
  # -- Ingress class name
  className: "nginx"
  # -- Ingress annotations
  annotations: {}
  # -- Ingress hosts
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  # -- TLS configuration
  tls: []

# Resource limits
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Autoscaling configuration
autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

# Node selector
nodeSelector: {}

# Tolerations
tolerations: []

# Affinity rules
affinity: {}

# -- Topology spread constraints
topologySpreadConstraints: []

# Pod disruption budget
podDisruptionBudget:
  enabled: true
  minAvailable: 1
  # maxUnavailable: 1

# Liveness probe
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

# Readiness probe
readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

# Environment variables
env: []
  # - name: LOG_LEVEL
  #   value: "info"

# Environment variables from secrets/configmaps
envFrom: []
  # - secretRef:
  #     name: app-secrets
  # - configMapRef:
  #     name: app-config

# Extra volumes
extraVolumes: []
  # - name: config
  #   configMap:
  #     name: app-config

# Extra volume mounts
extraVolumeMounts: []
  # - name: config
  #   mountPath: /app/config
  #   readOnly: true

# -- Additional labels
labels: {}

# Metrics/Prometheus
metrics:
  enabled: false
  port: 9090
  path: /metrics
  serviceMonitor:
    enabled: false
    interval: 30s
    scrapeTimeout: 10s

# Redis subchart
redis:
  enabled: false
  architecture: standalone
  auth:
    enabled: true
    existingSecret: ""

# PostgreSQL subchart
postgresql:
  enabled: false
  auth:
    database: app
    existingSecret: ""
```

### Template Helpers (_helpers.tpl)

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "webapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "webapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "webapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "webapp.labels" -}}
helm.sh/chart: {{ include "webapp.chart" . }}
{{ include "webapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "webapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "webapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "webapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "webapp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "webapp.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{/*
Create image pull secrets
*/}}
{{- define "webapp.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
```

### Deployment Template

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "webapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "webapp.labels" . | nindent 8 }}
    spec:
      {{- include "webapp.imagePullSecrets" . | nindent 6 }}
      serviceAccountName: {{ include "webapp.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: {{ include "webapp.image" . }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
            {{- if .Values.metrics.enabled }}
            - name: metrics
              containerPort: {{ .Values.metrics.port }}
              protocol: TCP
            {{- end }}
          {{- with .Values.env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          livenessProbe:
            {{- toYaml .Values.livenessProbe | nindent 12 }}
          readinessProbe:
            {{- toYaml .Values.readinessProbe | nindent 12 }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            {{- with .Values.extraVolumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
      volumes:
        - name: tmp
          emptyDir: {}
        {{- with .Values.extraVolumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

## Values Schema Validation

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["image"],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100,
      "description": "Number of pod replicas"
    },
    "image": {
      "type": "object",
      "required": ["repository"],
      "properties": {
        "repository": {
          "type": "string",
          "description": "Container image repository"
        },
        "tag": {
          "type": "string",
          "description": "Container image tag"
        },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"],
          "default": "IfNotPresent"
        }
      }
    },
    "service": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string",
          "enum": ["ClusterIP", "NodePort", "LoadBalancer"],
          "default": "ClusterIP"
        },
        "port": {
          "type": "integer",
          "minimum": 1,
          "maximum": 65535
        }
      }
    },
    "ingress": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "className": {
          "type": "string"
        },
        "hosts": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["host"],
            "properties": {
              "host": {
                "type": "string",
                "format": "hostname"
              },
              "paths": {
                "type": "array",
                "items": {
                  "type": "object",
                  "required": ["path"],
                  "properties": {
                    "path": {
                      "type": "string"
                    },
                    "pathType": {
                      "type": "string",
                      "enum": ["Prefix", "Exact", "ImplementationSpecific"]
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "resources": {
      "type": "object",
      "properties": {
        "limits": {
          "type": "object",
          "properties": {
            "cpu": { "type": "string" },
            "memory": { "type": "string" }
          }
        },
        "requests": {
          "type": "object",
          "properties": {
            "cpu": { "type": "string" },
            "memory": { "type": "string" }
          }
        }
      }
    }
  }
}
```

## Chart Hooks

```yaml
# templates/hooks/db-migrate.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "webapp.fullname" . }}-db-migrate
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    metadata:
      name: {{ include "webapp.fullname" . }}-db-migrate
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: {{ include "webapp.image" . }}
          command: ["./migrate.sh"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "webapp.fullname" . }}-db
                  key: url
  backoffLimit: 3
```

## Chart Testing

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "webapp.fullname" . }}-test-connection"
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  containers:
    - name: wget
      image: busybox:1.36
      command: ['wget']
      args: ['{{ include "webapp.fullname" . }}:{{ .Values.service.port }}/health']
  restartPolicy: Never
```

## Security Best Practices

### Pod Security Standards

```yaml
# Restricted pod security
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
      - ALL
```

### Network Policies

```yaml
# templates/networkpolicy.yaml
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "webapp.fullname" . }}
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "webapp.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
      ports:
        - protocol: TCP
          port: {{ .Values.service.targetPort }}
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: postgresql
      ports:
        - protocol: TCP
          port: 5432
{{- end }}
```

## OCI Registry Support

```bash
# Login to OCI registry
helm registry login ghcr.io -u username -p token

# Push chart to OCI registry
helm package charts/webapp
helm push webapp-2.5.0.tgz oci://ghcr.io/company/charts

# Pull from OCI registry
helm pull oci://ghcr.io/company/charts/webapp --version 2.5.0

# Install from OCI registry
helm install my-app oci://ghcr.io/company/charts/webapp --version 2.5.0
```

## Related Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Artifact Hub](https://artifacthub.io/)
- [Helm Plugin Directory](https://helm.sh/docs/community/related/)
