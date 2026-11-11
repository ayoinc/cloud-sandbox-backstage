{{/*
Name of the chart, used in labels.
*/}}
{{- define "${{ values.name }}.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the release's resources. Kubernetes names are limited to 63
characters; the release name is not repeated when it contains the chart name.
*/}}
{{- define "${{ values.name }}.fullname" -}}
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
Chart name and version, as used by the chart label.
*/}}
{{- define "${{ values.name }}.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Labels of every resource.
*/}}
{{- define "${{ values.name }}.labels" -}}
helm.sh/chart: {{ include "${{ values.name }}.chart" . }}
{{ include "${{ values.name }}.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Labels that select the pods. They must never change for a release.
*/}}
{{- define "${{ values.name }}.selectorLabels" -}}
app.kubernetes.io/name: {{ include "${{ values.name }}.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the ServiceAccount the pods run as.
*/}}
{{- define "${{ values.name }}.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "${{ values.name }}.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image reference: by digest when one is given, otherwise by tag, which
defaults to the appVersion of the chart.
*/}}
{{- define "${{ values.name }}.image" -}}
{{- if .Values.image.digest }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}
{{- end }}
