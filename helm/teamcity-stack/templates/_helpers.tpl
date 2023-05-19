{{- define "tc.name" }}
{{- default .Chart.Name .Values.teamcity.nameOverride -}}
{{- end }}

{{- define "tc.metadata.labels" }}
app.kubernetes.io/part-of: TeamCity
app.kubernetes.io/name: {{ include "tc.name" $ }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/component: server
{{- end }}
