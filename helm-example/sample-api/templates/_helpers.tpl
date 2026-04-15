{{- define "sample-api.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sample-api.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sample-api.labels" -}}
app.kubernetes.io/name: {{ include "sample-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
environment: {{ .Values.environment | quote }}
{{ with .Values.podLabels }}
{{- toYaml . }}
{{- end }}
{{- end -}}

{{- define "sample-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sample-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
environment: {{ .Values.environment | quote }}
{{- end -}}
