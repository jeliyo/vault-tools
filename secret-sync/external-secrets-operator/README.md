# external secrets operator example

Basic setup of the External Secrets Operator with k8s auth. Does just
enough to populate a Kubernetes secret from Vault KV.

Since this operator doesn't provision service account tokens,
secretstore.yaml creates a legacy long-lived service account token
Secret, which is then referenced in the SecretStore CR.

```bash
#!/usr/bin/env bash

helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
     external-secrets/external-secrets \
     -n external-secrets \
     --create-namespace \
     --set installCRDs=true

helm install vault hashicorp/vault -n vault -f values.yaml --create-namespace

kaf service-account-internal-app.yml

./setup-vault.sh

kaf secretstore.yaml
```
