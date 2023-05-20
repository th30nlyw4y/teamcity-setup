{{- define "tc.name" }}
{{- $ctx := .ctx }}
{{- $tc  := .ctx.Values.teamcity }}
{{- $component := ( .component | default "" ) }}
{{- eq (len $tc.nameOverride) 0 | ternary ( printf "%s-%s" $ctx.Chart.Name (default "server" $component) ) $tc.nameOverride }}
{{- end }}

{{- define "tc.metadata.labels" }}
{{- $ctx := .ctx }}
{{- $component := ( .component | default "" ) }}
app.kubernetes.io/part-of: TeamCity
app.kubernetes.io/name: {{ include "tc.name" . }}
app.kubernetes.io/version: {{ $ctx.Chart.AppVersion }}
app.kubernetes.io/component: {{ default "server" $component}}
{{- end }}
