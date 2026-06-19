{{/*
Expand the name of the chart.
*/}}
{{- define "kserve-runtime-configs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kserve-runtime-configs.fullname" -}}
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
{{- define "kserve-runtime-configs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kserve-runtime-configs.labels" -}}
helm.sh/chart: {{ include "kserve-runtime-configs.chart" . }}
{{ include "kserve-runtime-configs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kserve-runtime-configs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kserve-runtime-configs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Repoint the llm-d preset images from values.

The LLMInferenceServiceConfig presets embed controller-side Go templates and are
NOT parseable YAML, so we cannot fromYaml/deepMerge them — only string-replace.
The search pattern is keyed on the ORIGINAL hardcoded repo (tag-agnostic), so a
tag bump in config/llmisvcconfig keeps getting repointed. regexReplaceAllLiteral
avoids "$" expansion in the replacement.

Usage: include "kserve-runtime-configs.replaceLLMImages" (list $content .Values)
*/}}
{{- define "kserve-runtime-configs.replaceLLMImages" -}}
{{- $content := index . 0 -}}
{{- $imgs := (((index . 1).kserve | default dict).llmisvcConfigs | default dict).images | default dict -}}
{{- $map := dict
    "ghcr.io/llm-d/llm-d-cuda" ($imgs.workload | default dict)
    "ghcr.io/llm-d/llm-d-routing-sidecar" ($imgs.routingSidecar | default dict)
    "ghcr.io/llm-d/llm-d-inference-scheduler" ($imgs.scheduler | default dict)
    "ghcr.io/llm-d/llm-d-uds-tokenizer" ($imgs.tokenizer | default dict) -}}
{{- range $orig, $img := $map -}}
{{- if and $img.image $img.tag -}}
{{- $pattern := printf "%s:[^\\s\"']+" ($orig | replace "." "\\.") -}}
{{- $content = regexReplaceAllLiteral $pattern $content (printf "%s:%s" $img.image $img.tag) -}}
{{- end -}}
{{- end -}}
{{- $content -}}
{{- end -}}

{{/*
Apply imagePullPolicy to every preset container. The presets ship
"imagePullPolicy: IfNotPresent", so a plain replace covers all of them and is a
no-op when the value is left at the default.

Usage: include "kserve-runtime-configs.applyLLMImagePullPolicy" (list $content .Values)
*/}}
{{- define "kserve-runtime-configs.applyLLMImagePullPolicy" -}}
{{- $content := index . 0 -}}
{{- $llmisvcConfigs := ((index . 1).kserve | default dict).llmisvcConfigs | default dict -}}
{{- $policy := $llmisvcConfigs.imagePullPolicy | default "IfNotPresent" -}}
{{- $content | replace "imagePullPolicy: IfNotPresent" (printf "imagePullPolicy: %s" $policy) -}}
{{- end -}}

