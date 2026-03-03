{{/*
Expand the name of the chart.
*/}}
{{- define "ethiack-beacon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ethiack-beacon.fullname" -}}
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
Common labels
*/}}
{{- define "ethiack-beacon.labels" -}}
helm.sh/chart: {{ include "ethiack-beacon.chart" . }}
{{ include "ethiack-beacon.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ethiack-beacon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ethiack-beacon.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Chart label
*/}}
{{- define "ethiack-beacon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "ethiack-beacon.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ethiack-beacon.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the credentials secret
*/}}
{{- define "ethiack-beacon.secretName" -}}
{{- if .Values.credentials.existingSecret }}
{{- .Values.credentials.existingSecret }}
{{- else }}
{{- include "ethiack-beacon.fullname" . }}-credentials
{{- end }}
{{- end }}

{{/*
Name of the PVC
*/}}
{{- define "ethiack-beacon.pvcName" -}}
{{- include "ethiack-beacon.fullname" . }}-state
{{- end }}
