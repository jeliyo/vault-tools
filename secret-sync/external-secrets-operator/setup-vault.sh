#!/bin/bash

cat <<EOF > /tmp/vault-commands.sh
vault secrets enable -path=internal kv-v2
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
vault kv get internal/database/config
vault kv put internal/database/spec.keys username.key="db--spec-username" password="db-spec-password"

vault auth enable kubernetes
vault write auth/kubernetes/config \
        token_reviewer_jwt="\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
        disable_iss_validation=true \
        kubernetes_host="https://\$KUBERNETES_PORT_443_TCP_ADDR:443" \
        kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
vault policy write internal-app - <<EOH
path "internal/data/database/config" {
  capabilities = ["read"]
}
path "internal/data/database/*" {
  capabilities = ["read", "list"]
}
EOH
vault write auth/kubernetes/role/internal-app \
        bound_service_account_names=internal-app \
        bound_service_account_namespaces=default,vault,payrole,tvoran-vault-helm,not-hashicorp,tvoran-payrole \
        policies=internal-app \
        ttl=24h
EOF

kubectl cp /tmp/vault-commands.sh vault/vault-0:/tmp/
kubectl -n vault exec vault-0 -- sh -c 'sh /tmp/vault-commands.sh'

# kubectl apply -f service-account-internal-app.yml
