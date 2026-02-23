{{- define "scratchbird-sidecar.name" -}}
scratchbird-sidecar
{{- end }}

{{- define "scratchbird-sidecar.fullname" -}}
{{- if .Values.deployment.fullnameOverride -}}
{{- .Values.deployment.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.deployment.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "scratchbird-sidecar.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "scratchbird-sidecar.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
