{{/*
Chart name and release-qualified fullname.
*/}}
{{- define "posts-api.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "posts-api.fullname" -}}
{{- if eq .Release.Name .Chart.Name -}}
{{- .Chart.Name -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "posts-api.labels" -}}
app.kubernetes.io/name: {{ include "posts-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "posts-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "posts-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "posts-api.mariadbFullname" -}}
{{- printf "%s-mariadb" (include "posts-api.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name of the Secret holding DB credentials: the user-provided one if set,
otherwise a chart-managed one.
*/}}
{{- define "posts-api.dbSecretName" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecret -}}
{{- else -}}
{{- printf "%s-db-credentials" (include "posts-api.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "posts-api.dbHost" -}}
{{- if .Values.database.embedded -}}
{{- include "posts-api.mariadbFullname" . -}}
{{- else -}}
{{- .Values.database.host -}}
{{- end -}}
{{- end -}}
