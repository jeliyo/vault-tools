#!/bin/bash

AUTH_PATH=kubernetes-long-lived

# Get long-lived (legacy) `vault` service account token
REVIEWER_TOKEN=$(kubectl get secret -n vault "$(kubectl get serviceaccount -n vault vault -o jsonpath='{.secrets[0].name}')" -o json | jq -r .data.token | base64 -d)

cat <<EOF > /tmp/vault-commands.sh
vault secrets enable -path=internal kv-v2 || true
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
vault kv get internal/database/config

vault auth enable -path=${AUTH_PATH?} kubernetes
vault write auth/${AUTH_PATH?}/config \
        token_reviewer_jwt="${REVIEWER_TOKEN?}" \
        disable_iss_validation=true \
        kubernetes_host="https://\$KUBERNETES_PORT_443_TCP_ADDR:443"
        
vault policy write internal-app - <<EOH
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOH

vault write auth/${AUTH_PATH?}/role/internal-app \
        bound_service_account_names=internal-app \
        bound_service_account_namespaces=default,vault,payrole,tvoran-vault-helm,not-hashicorp,tvoran-payrole \
        policies=internal-app \
        ttl=24h
EOF

kubectl cp /tmp/vault-commands.sh vault/vault-0:/tmp/
kubectl -n vault exec vault-0 -- sh -c 'sh /tmp/vault-commands.sh'

kubectl apply -f service-account-internal-app.yml
