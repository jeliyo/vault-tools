#!/bin/bash

AUTH_PATH=kubernetes-client-jwt

cat <<EOF > /tmp/vault-commands.sh
vault secrets enable -path=internal kv-v2 || true
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
vault kv get internal/database/config

# configure auth mount to use client jwt for token review api. since this is
# running in kubernetes, still read the ca from the pod
vault auth enable -path=${AUTH_PATH?} kubernetes
vault write auth/${AUTH_PATH}/config \
        disable_iss_validation=true \
        disable_local_ca_jwt=true \
        kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
        kubernetes_host="https://\$KUBERNETES_PORT_443_TCP_ADDR:443"
vault policy write internal-app-client-jwt - <<EOH
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOH
vault write auth/${AUTH_PATH}/role/internal-app \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=default,vault,payrole,tvoran-vault-helm,not-hashicorp,tvoran-payrole \
        policies=internal-app-client-jwt \
        ttl=24h
EOF

kubectl cp /tmp/vault-commands.sh vault/vault-0:/tmp/
kubectl -n vault exec vault-0 -- sh -c 'sh /tmp/vault-commands.sh'

kubectl apply -f client-service-account-binding.yaml
