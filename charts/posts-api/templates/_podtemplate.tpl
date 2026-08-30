{{/*
Shared pod template, used by both the plain Deployment and the Argo
Rollout (the two are mutually exclusive, toggled by
.Values.argoRollouts.enabled), so the two rollout mechanisms never drift
apart on container spec, probes, security context, etc.
*/}}
{{- define "posts-api.podTemplate" -}}
metadata:
  labels:
    {{- include "posts-api.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: app
spec:
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: {{ .Values.topologySpreadConstraints.zoneTopologyKey }}
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          {{- include "posts-api.selectorLabels" . | nindent 10 }}
          app.kubernetes.io/component: app
    - maxSkew: 1
      topologyKey: {{ .Values.topologySpreadConstraints.hostTopologyKey }}
      whenUnsatisfiable: ScheduleAnyway
      labelSelector:
        matchLabels:
          {{- include "posts-api.selectorLabels" . | nindent 10 }}
          app.kubernetes.io/component: app
  containers:
    - name: {{ .Chart.Name }}
      image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      ports:
        - name: http
          containerPort: {{ .Values.app.port }}
      envFrom:
        - configMapRef:
            name: {{ include "posts-api.fullname" . }}-config
        - secretRef:
            name: {{ include "posts-api.dbSecretName" . }}
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
      volumeMounts:
        - name: tmp
          mountPath: /tmp
      resources:
        {{- toYaml .Values.resources | nindent 8 }}
      readinessProbe:
        httpGet:
          path: /posts
          port: http
        initialDelaySeconds: 5
        periodSeconds: 10
        timeoutSeconds: 3
        failureThreshold: 3
      livenessProbe:
        httpGet:
          path: /health
          port: http
        initialDelaySeconds: 10
        periodSeconds: 15
        timeoutSeconds: 3
        failureThreshold: 3
  volumes:
    - name: tmp
      emptyDir: {}
{{- end -}}
