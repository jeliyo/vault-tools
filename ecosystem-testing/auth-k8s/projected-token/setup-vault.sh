#!/bin/bash

## Get cluster issuer from openid endpoint
# kubectl proxy &
# K_PID=$!
# sleep 1
# export ISSUER=$(curl -s http://127.0.0.1:8001/.well-known/openid-configuration | jq -r .issuer)
# kill $K_PID

# if [ -z $ISSUER ] || [ $ISSUER == "null" ]; then
#     export ISSUER=kubernetes/serviceaccount
# fi

# echo $ISSUER, $K_PID

cat <<EOF > /tmp/vault-commands.sh
vault secrets enable -path=internal kv-v2
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
vault kv get internal/database/config
vault auth enable kubernetes
vault write auth/kubernetes/config \
        disable_iss_validation=true \
        kubernetes_host="https://\$KUBERNETES_PORT_443_TCP_ADDR:443"
vault policy write internal-app - <<EOH
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOH
vault write auth/kubernetes/role/internal-app \
        bound_service_account_names=internal-app \
        bound_service_account_namespaces=default,vault,payrole,tvoran-vault-helm,not-hashicorp,tvoran-payrole \
        policies=internal-app \
        ttl=24h
EOF

# issuer=${ISSUER?} \

kubectl cp /tmp/vault-commands.sh vault/vault-0:/tmp/
kubectl -n vault exec vault-0 -- sh -c 'sh -x /tmp/vault-commands.sh'

kubectl apply -f service-account-internal-app.yml
