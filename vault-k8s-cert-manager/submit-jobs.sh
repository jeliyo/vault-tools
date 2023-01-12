#!/bin/bash

for n in `seq 1 100`; do
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: sleep-${n}
spec:
  backoffLimit: 0
  template:
    metadata:
      name: sleep-${n}
      labels:
        app: sleep
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "internal-app"
        vault.hashicorp.com/agent-inject-secret-database-config.txt: "internal/data/database/config"
        vault.hashicorp.com/agent-inject-template-database-config.txt: |
          {{- with secret "internal/data/database/config" -}}
          postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@postgres:5432/wizard
          {{- end -}}
        vault.hashicorp.com/agent-pre-populate-only: "true"
        vault.hashicorp.com/agent-limits-cpu: "5m"
        vault.hashicorp.com/agent-limits-mem: "5Mi"
        vault.hashicorp.com/agent-requests-cpu: "1m"
        vault.hashicorp.com/agent-requests-mem: "2Mi"
    spec:
      serviceAccountName: internal-app
      restartPolicy: Never
      containers:
      - name: sleep
        image: alpine
        command: ["/bin/ls"]
        args: ["/vault/secrets/database-config.txt"]
EOF

done
